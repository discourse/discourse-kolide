# frozen_string_literal: true

# name: discourse-kolide
# about: Integration features between Kolide and Discourse
# version: 1.0
# author: Vinoth Kannan <svkn.87@gmail.com>
# url: https://github.com/discourse/discourse-kolide
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :kolide_enabled

after_initialize do
  module ::Kolide
    PLUGIN_NAME = 'discourse-kolide'

    def self.sync!
      api = ::Kolide::Api.new
      response = api.get("issues/open")

      return if response[:error].present?

      open_issue_ids = []
      device_ids = []
      response["data"].each do |issue_data|
        issue = ::Kolide::Issue.find_or_create_by_json(issue_data)
        next if issue.blank?

        issue.update(updated_at: Time.zone.now)
        open_issue_ids << issue.id
        device_ids << issue.device_id if device_ids.exclude?(issue.device_id)
      end

      ::Kolide::Issue.where(resolved: false).where.not(id: open_issue_ids).update_all(resolved: true)
      user_ids = ::Kolide::Device.where(id: device_ids).where.not(user_id: nil).pluck(:user_id).uniq

      User.where(id: user_ids).each do |user|
        Alert.new(user).remind!
      end
    end
  end

  [
    '../app/controllers/webhooks_controller.rb',
    '../app/jobs/regular/alert_user.rb',
    '../app/jobs/scheduled/sync_kolide.rb',
    '../app/models/device.rb',
    '../app/models/issue.rb',
    '../lib/alert.rb',
    '../lib/api.rb'
  ].each { |path| load File.expand_path(path, __FILE__) }

  reloadable_patch do |plugin|
    require_dependency 'user'
    class ::User
      def self.find_by_kolide_json(data)
        custom_field = UserCustomField.find_or_initialize_by(name: "kolide_person_id", value: data["id"])
        return custom_field.user unless custom_field.new_record?

        email = data["email"]
        user = User.find_by_email(email)

        if user.blank?
          Discourse.warn("Unable find the Discourse user for email address '#{email}'")
          return
        end

        custom_field.user_id = user.id
        custom_field.save!

        user
      end
    end
  end
end
