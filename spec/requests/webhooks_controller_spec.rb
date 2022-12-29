# frozen_string_literal: true

require "rails_helper"
require "openssl"
require "json"
require_relative "../spec_helper"

RSpec.describe ::Kolide::WebhooksController do
  include_context "with kolide spec helper"

  let(:secret) { SiteSetting.kolide_webhook_secret = "WEBHOOK SECRET" }

  before { SiteSetting.queue_jobs = false }

  def post_request(body)
    post "/kolide/webhooks",
         params: body,
         headers: {
           HTTP_AUTHORIZATION: OpenSSL::HMAC.hexdigest("sha256", secret, body),
         }
  end

  describe "index" do
    it "updates the device to corresponding user when reassigned" do
      body = get_kolide_response("reassigned.json")
      data = JSON.parse(body)["data"]
      device_id = data["device_id"]
      device = Fabricate(:kolide_device, uid: device_id, user_id: nil)
      user = Fabricate(:user, email: data["new_owner"]["email"])

      post_request(body)

      expect(response.status).to eq(200)
      expect(Kolide::Device.find_by_uid(device_id).user_id).to eq(user.id)
    end

    it "removes the device and updates the user PM" do
      body = get_kolide_response("destroyed.json")
      data = JSON.parse(body)["data"]
      device_id = data["device_id"]
      user = Fabricate(:user)
      device = Fabricate(:kolide_device, uid: device_id, user: user)
      ::Kolide::UserAlert.any_instance.expects(:remind!).once

      post_request(body)

      expect(response.status).to eq(200)
      expect(Kolide::Device.find_by_uid(device_id)).to be_nil
    end

    it "updates the user alert PM post when issue is resolved" do
      body = get_kolide_response("resolved.json")
      data = JSON.parse(body)["data"]
      user = Fabricate(:user)
      device = Fabricate(:kolide_device, uid: data["device_id"], user: user)
      issue = Fabricate(:kolide_issue, uid: data["issue_id"], device: device)

      post_request(body)

      expect(response.status).to eq(200)
      expect(issue.reload.resolved).to be_truthy
      pm = Topic.private_messages_for_user(user).last
      expect(pm.first_post.raw).to eq(I18n.t("kolide.alert.no_issues"))
    end
  end
end
