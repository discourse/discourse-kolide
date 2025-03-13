# frozen_string_literal: true

# name: discourse-kolide
# about: Integration features between Kolide and Discourse
# version: 1.0
# author: Vinoth Kannan <svkn.87@gmail.com>
# url: https://github.com/discourse/discourse-kolide
# required_version: 2.7.0

enabled_site_setting :kolide_enabled

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

  require_relative "app/controllers/webhooks_controller"
  require_relative "app/controllers/devices_controller"
  require_relative "app/controllers/issues_controller"
  require_relative "app/jobs/scheduled/sync_kolide"
  require_relative "app/models/kolide/check"
  require_relative "app/models/kolide/device"
  require_relative "app/models/kolide/issue"
  require_relative "app/serializers/kolide/device_serializer"
  require_relative "lib/api"
  require_relative "lib/application_controller_extension"
  require_relative "lib/group_alert"
  require_relative "lib/user_alert"
  require_relative "lib/user_extension"

  Kolide::Engine.routes.draw do
    post "/webhooks" => "webhooks#index"
    get "/devices" => "devices#index"
    put "/devices/refresh" => "devices#refresh"
    post "/devices/current" => "devices#current"
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
    User.prepend(::Kolide::UserExtension)
    ApplicationController.prepend(::Kolide::ApplicationControllerExtension)
  end
end
