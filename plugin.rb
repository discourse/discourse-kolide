# frozen_string_literal: true

# name: discourse-kolide
# about: Integration features between Kolide and Discourse
# version: 1.0
# author: Vinoth Kannan <svkn.87@gmail.com>
# url: https://github.com/discourse/discourse-kolide
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :kolide_enabled

register_asset "stylesheets/kolide.scss"

after_initialize do
  module ::Kolide
    PLUGIN_NAME = "discourse-kolide"

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace Kolide
    end

    def self.api
      @api ||= ::Kolide::Api.new
    end

    def self.sync!
      Device.sync_all!
      Check.sync_all!
      device_ids = Issue.sync_open!
      user_ids = ::Kolide::Device.where(id: device_ids).where.not(user_id: nil).pluck(:user_id).uniq

      User.where(id: user_ids).each { |user| UserAlert.new(user).remind! }

      GroupAlert.new.remind! if SiteSetting.kolide_admin_group_name.present?
    end
  end

  %w[
    ../app/controllers/webhooks_controller.rb
    ../app/controllers/devices_controller.rb
    ../app/controllers/issues_controller.rb
    ../app/jobs/scheduled/sync_kolide.rb
    ../app/models/kolide/check.rb
    ../app/models/kolide/device.rb
    ../app/models/kolide/issue.rb
    ../lib/api.rb
    ../lib/application_controller_extension.rb
    ../lib/group_alert.rb
    ../lib/user_alert.rb
    ../lib/user_extension.rb
  ].each { |path| load File.expand_path(path, __FILE__) }

  Kolide::Engine.routes.draw do
    post "/webhooks" => "webhooks#index"
    get "/devices" => "devices#index"
    put "/devices/:device_id/assign" => "devices#assign"
    post "/issues/:issue_id/recheck" => "issues#recheck"
  end

  Discourse::Application.routes.append do
    mount ::Kolide::Engine, at: "/kolide"

    get "u/:username/preferences/kolide" => "users#preferences",
        :constraints => {
          username: RouteFormat.username,
        }
  end

  register_notification_consolidation_plan(Kolide::UserAlert.notification_consolidation_plan)

  reloadable_patch do |plugin|
    User.class_eval { prepend ::Kolide::UserExtension }
    ApplicationController.class_eval { prepend ::Kolide::ApplicationControllerExtension }
  end
end
