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

    def sync!
      api = ::Kolide::Api.new
      data = api.get("issues")

      return if data[:error].present?

      
    end
  end

  [
    '../app/controllers/webhooks_controller.rb',
    '../app/jobs/regular/alert_user.rb',
    '../app/jobs/scheduled/sync_kolide.rb',
    '../lib/alert.rb',
    '../lib/api.rb'
  ].each { |path| load File.expand_path(path, __FILE__) }
end
