# frozen_string_literal: true

RSpec.describe ApplicationController do
  fab!(:user) { Fabricate(:user) }
  fab!(:device) { Fabricate(:kolide_device, user: user, ip_address: "10.7.8.9") }

  describe "#ensure_device_onboarded" do
    before do
      SiteSetting.kolide_enabled = true
      sign_in(user)
    end

    it "should not create cookie if device not found" do
      get "/", headers: { "REMOTE_ADDR" => "1.2.3.4" }
      expect(response.cookies["kolide_onboarded"]).to be_nil
    end

    it "should create cookie if device exists" do
      device.update(ip_address: "1.2.3.4")
      get "/", headers: { "REMOTE_ADDR" => "1.2.3.4" }
      expect(response.cookies["kolide_onboarded"]).to eq(true.to_s)
    end
  end
end
