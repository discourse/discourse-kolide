# frozen_string_literal: true

module ::Kolide

  class Issue < ::ActiveRecord::Base
    self.table_name = "kolide_issues"

    belongs_to :device

    def self.find_or_create_by_json(data)
      issue = where(uid: data["id"]).first_or_initialize(
        title: data["title"],
        reported_at: data["timestamp"]
      )

      if issue.device_id.blank?
        device = Device.find_or_create_by_json(data["device"])
        return if device.blank?
        issue.device_id = device.id
      end

      issue.ignored = data["ignored"],
      issue.resolved_at = data["resolved_at"]
      issue.resolved = issue.resolved_at.present?
      issue.save! if issue.changed?

      issue
    end

    def self.sync_open!
      response = Kolide.api.get("issues/open")
      return if response[:error].present?

      open_issue_ids = []
      device_ids = []
      response["data"].each do |data|
        issue = find_or_create_by_json(data)
        next if issue.blank?

        issue.update(updated_at: Time.zone.now)
        open_issue_ids << issue.id
        device_ids << issue.device_id if device_ids.exclude?(issue.device_id)
      end

      resolved_issues = where(resolved: false).where.not(id: open_issue_ids)
      resolved_issues.update_all(resolved: true, resolved_at: Time.zone.now)

      device_ids += resolved_issues.pluck(:device_id)
      device_ids.uniq
    end

    def self.sync!(id, event)
      issue = find_by(uid: id)

      if issue.blank?
        data = Kolide.api.get("issues/#{id}")
        return if data[:error].present?

        issue = find_or_create_by_json(data)
        return if issue.blank?
      end

      issue.update(resolved: true) if event == "issues.resolved"
      user = issue.device.user_id
      Alert.new(user).remind!
    end
  end
end
