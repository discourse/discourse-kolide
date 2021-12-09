# frozen_string_literal: true

# name: discourse-kolide
# about: Integration features between Kolide and Discourse
# version: 1.0
# author: Vinoth Kannan <svkn.87@gmail.com>
# url: https://github.com/discourse/discourse-kolide
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :kolide_enabled

register_asset 'stylesheets/kolide.scss'

after_initialize do
  module ::Kolide
    PLUGIN_NAME = 'discourse-kolide'

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace Kolide
    end

    def self.api
      @api ||= ::Kolide::Api.new
    end

    def self.sync!
      Device.sync_all!
      device_ids = Issue.sync_open!
      user_ids = ::Kolide::Device.where(id: device_ids).where.not(user_id: nil).pluck(:user_id).uniq

      User.where(id: user_ids).each do |user|
        UserAlert.new(user).remind!
      end

      GroupAlert.new.remind! if SiteSetting.kolide_admin_group_name.present?
    end
  end

  [
    '../app/controllers/webhooks_controller.rb',
    '../app/jobs/scheduled/sync_kolide.rb',
    '../app/models/device.rb',
    '../app/models/issue.rb',
    '../lib/api.rb',
    '../lib/user_alert.rb',
    '../lib/group_alert.rb'
  ].each { |path| load File.expand_path(path, __FILE__) }

  Kolide::Engine.routes.draw do
    post '/webhooks' => 'webhooks#index'
  end

  Discourse::Application.routes.prepend do
    mount ::Kolide::Engine, at: '/kolide'
  end

  reloadable_patch do |plugin|
    require_dependency 'user'
    class ::User
      def self.find_by_kolide_json(data)
        return if data.blank?

        custom_field = UserCustomField.find_or_initialize_by(name: "kolide_person_id", value: data["id"])
        return custom_field.user unless custom_field.new_record?

        email = data["email"]
        user = User.find_by_email(email)

        if user.blank?
          Rails.logger.warn("Unable find the Discourse user for email address '#{email}'")
          return
        end

        custom_field.user_id = user.id
        custom_field.save!

        user
      end
    end

    add_to_serializer(:site, :non_onboarded_device, false) do
      !::Kolide::Device.where(user_id: scope.user.id, ip_address: scope.request.ip).exists?
    end

    add_to_serializer(:site, :include_non_onboarded_device?) do
      scope.user.present? && !MobileDetection.mobile_device?(scope.request.user_agent)
    end
  end
end
