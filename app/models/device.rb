# frozen_string_literal: true

module ::Kolide

  class Device < ::ActiveRecord::Base
    self.table_name = "kolide_devices"

    has_many :issues

    def self.find_or_create_by_json(data)
      device = find_by(uid: data["id"])
      ip_address = data["remote_ip"]

      if device.present?
        device.ip_address = ip_address if device.ip_address != ip_address
        device.user_id = find_user(data)&.id if device.user_id.blank?
        device.save! if device.changed?

        return device
      end

      create!(
        uid: data["id"],
        user_id: find_user(data)&.id,
        name: data["name"],
        primary_user_name: data["primary_user_name"],
        hardware_model: data["hardware_model"],
        ip_address: ip_address
      )
    end

    def self.sync_all!
      response = Kolide.api.get("devices")
      return if response[:error].present?

      response["data"].each do |data|
        find_or_create_by_json(data)
      end
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
        device.update(user_id: user&.id) if data.user_id != user&.id
      end
    end

    def self.find_user(data)
      ::User.find_by_kolide_json(data["assigned_owner"])
    end
  end
end
