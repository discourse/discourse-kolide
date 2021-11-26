# frozen_string_literal: true

require 'openssl'
require 'json'

module ::Kolide

  class WebhooksController < ::ApplicationController

    skip_before_action :redirect_to_login_if_required, :preload_json, :check_xhr, :verify_authenticity_token

    def index
      body = request.body.read
      raise Discourse::InvalidAccess.new unless is_valid_signature?(body)

      data = JSON.parse(body)

      render body: nil, status: 200
    end
  
    private
  
    def is_valid_signature?(body)
      signature = request.headers['HTTP_AUTHORIZATION']
      signature == OpenSSL::HMAC.hexdigest('sha256', SiteSetting.kolide_webhook_secret, body)
    end

  end
end
