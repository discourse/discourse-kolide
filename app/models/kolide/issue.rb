# frozen_string_literal: true

module Kolide
  class Issue < ::ActiveRecord::Base
    self.table_name = "kolide_issues"

    belongs_to :device
    belongs_to :check

    def identifier_markdown
      "[^#{id}]"
    end

    def markdown
      "#{title} #{identifier_markdown} [kolide-recheck issue=#{id}]"
    end

    def self.find_or_create_by_json(data)
      issue =
        where(uid: data["id"]).first_or_initialize(
          title: data["title"],
          reported_at: data["timestamp"],
        )

      if issue.device_id.blank?
        device = Device.find_or_create_by_json(data["device"])
        return if device.blank?
        issue.device_id = device.id
      end

      if issue.check_id.blank?
        check = Check.find_by(uid: data["check_id"])
        return if check.blank?
        issue.check_id = check.id
      end

      issue.ignored = data["ignored"]
      issue.resolved_at = data["resolved_at"]
      issue.resolved = issue.resolved_at.present?
      issue.key = data["issue_key"]
      issue.value = data["issue_value"]
      issue.data = data["value"].to_json
      issue.save! if issue.changed?

      issue
    end

    def self.sync_open!
      response = Kolide.api.get_all("issues/open")
      return if response[:error].present?

      open_issue_ids = []
      device_ids = []
      response[:data].each do |data|
        issue = find_or_create_by_json(data)
        next if issue.blank?

        issue.update(updated_at: Time.zone.now)
        open_issue_ids << issue.id
        device_ids << issue.device_id if device_ids.exclude?(issue.device_id)
      end

      resolved_issues = where(resolved: false).where.not(id: open_issue_ids)
      device_ids += resolved_issues.pluck(:device_id)
      resolved_issues.update_all(resolved: true, resolved_at: Time.zone.now)

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
      user = issue.device.user
      UserAlert.new(user).remind! if user.present?
    end
  end
end
