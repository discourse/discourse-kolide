# frozen_string_literal: true

require 'openssl'
require 'json'

module ::Kolide

  class WebhooksController < ::ApplicationController

    skip_before_action :redirect_to_login_if_required, :preload_json, :check_xhr, :verify_authenticity_token

    def index
      body = request.body.read
      raise Discourse::InvalidAccess.new unless is_valid_signature?(body)

      payload = JSON.parse(body)
      Rails.logger.warn("Kolide verbose log for Webhook:\n  Payload = #{payload.inspect}") if SiteSetting.kolide_verbose_log

      event = payload["event"]
      data = payload["data"]

      if ["issues.new", "issues.resolved"].include?(event)
        Issue.sync!(data["issue_id"], event)
      elsif ["devices.created", "devices.reassigned"].include?(event)
        Device.sync!(data["device_id"], event, data)
      elsif ["devices.destroyed"].include?(event)
        Device.find_by(uid: data["device_id"])&.destroy
      end

      render body: nil, status: 200
    end

    private

    def is_valid_signature?(body)
      signature = request.headers['HTTP_AUTHORIZATION']
      signature == OpenSSL::HMAC.hexdigest('sha256', SiteSetting.kolide_webhook_secret, body)
    end

  end
end
