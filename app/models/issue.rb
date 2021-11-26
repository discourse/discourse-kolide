# frozen_string_literal: true

module ::Kolide

  class Issue < ::ActiveRecord::Base
    self.table_name = "kolide_issues"

    belongs_to :device

    def self.find_or_create_by_json(data)
      issue = find_by(uid: data["id"])
      return issue if issue.present?

      device = Device.find_or_create_by_json(data["device"])
      return if device.blank?

      create!(
        uid: data["id"],
        device_id: device.id,
        title: data["title"],
        ignored: data["ignored"],
        reported_at: data["timestamp"],
        resolved_at: data["resolved_at"]
      )
    end
  end
end
