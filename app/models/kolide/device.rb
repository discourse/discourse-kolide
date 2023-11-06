# frozen_string_literal: true

module Kolide
  class Device < ::ActiveRecord::Base
    self.table_name = "kolide_devices"
    self.ignored_columns = ["primary_user_name"]

    has_many :issues, dependent: :destroy
    has_many :device_auth_tokens, dependent: :destroy, class_name: "Kolide::DeviceAuthToken"
    belongs_to :user

    after_destroy :update_user_alert_pm

    def update_user_alert_pm
      UserAlert.new(self.user).remind! if self.user.present?
    end

    def self.find_or_create_by_json(data)
      device = where(uid: data["id"]).first_or_initialize(hardware_model: data["hardware_model"])

      device.ip_address = data["remote_ip"]
      device.name = data["name"]
      device.user_id = find_user(data)&.id
      device.save! if device.changed?

      device
    end

    def self.sync_all!
      response = Kolide.api.get_all("devices")
      return if response[:error].present?

      device_ids = []
      response[:data].each do |data|
        device_ids << data["id"]
        find_or_create_by_json(data)
      end
      # delete the devices not available on Kolide
      where.not(uid: device_ids).destroy_all
    end

    def self.sync!(uid, event, data)
      device = find_by(uid: uid)

      if device.blank?
        payload = Kolide.api.get("devices/#{uid}")
        return if payload[:error].present?

        device = find_or_create_by_json(payload)
        return if device.blank?
      end

      if event == "devices.reassigned"
        user = User.find_by_kolide_json(data["new_owner"])
        device.update(user_id: user&.id) if data["user_id"] != user&.id
      end
    end

    def self.find_user(data)
      ::User.find_by_kolide_json(data["assigned_owner"])
    end
  end
end
