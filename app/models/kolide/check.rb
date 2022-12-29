# frozen_string_literal: true

module Kolide
  class Check < ::ActiveRecord::Base
    self.table_name = "kolide_checks"

    has_many :issues

    def self.find_or_create_by_json(data)
      check =
        where(uid: data["id"]).first_or_initialize(
          name: data["name"],
          display_name: data["display_name"],
          description: data["description"],
        )

      check.failing_device_count = data["failing_device_count"]
      check.delay = (data["notification_grace_period"].presence || 0) * 24
      check.save! if check.changed?

      check
    end

    def self.sync_all!
      response = Kolide.api.get("checks")
      return if response[:error].present?

      response["data"].each { |data| find_or_create_by_json(data) }
    end
  end
end
