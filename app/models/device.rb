# frozen_string_literal: true

module ::Kolide

  class Device < ::ActiveRecord::Base
    self.table_name = "kolide_devices"

    has_many :issues

    def self.find_or_create_by_json(data)
      device = find_by(uid: data["id"])
      return device if device.present?

      user = ::User.find_by_kolide_json(data["assigned_owner"])

      create!(
        uid: data["id"],
        user_id: user&.id,
        name: data["name"],
        primary_user_name: data["primary_user_name"],
        hardware_model: data["hardware_model"]
      )
    end
  end
end
