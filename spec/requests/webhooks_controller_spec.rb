# frozen_string_literal: true

require "rails_helper"
require 'openssl'
require 'json'
require_relative '../spec_helper'

RSpec.describe ::Kolide::WebhooksController do
  include_context "spec helper"

  let(:secret) { SiteSetting.kolide_webhook_secret = "WEBHOOK SECRET" }

  before do
    SiteSetting.queue_jobs = false
  end

  def post_request(body)
    post '/kolide/webhooks', params: body, headers: {
      'HTTP_AUTHORIZATION': OpenSSL::HMAC.hexdigest("sha256", secret, body)
    }
  end

  context "index" do
    it 'updates the device to corresponding user when reassigned' do
      body = get_kolide_response('reassigned.json')
      data = JSON.parse(body)["data"]
      device_id = data["device_id"]
      device = Fabricate(:kolide_device, uid: device_id, user_id: nil)
      user = Fabricate(:user, email: data["new_owner"]["email"])

      post_request(body)

      expect(response.status).to eq(200)
      expect(Kolide::Device.find_by_uid(device_id).user_id).to eq(user.id)
    end
  end
end
