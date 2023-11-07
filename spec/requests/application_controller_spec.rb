# frozen_string_literal: true

RSpec.describe ApplicationController do
  fab!(:user) { Fabricate(:user) }
  fab!(:device) { Fabricate(:kolide_device, user: user, ip_address: "10.7.8.9") }

  describe "#ensure_device_onboarded" do
    before do
      SiteSetting.kolide_enabled = true
      sign_in(user)
      user.custom_fields["kolide_person_id"] = "123"
      user.save_custom_fields
    end

    it "should create cookie if device not found" do
      freeze_time
      get "/"
      expect(response.cookies["kolide_non_onboarded"]).to eq(Time.now.to_i.to_s)
    end

    it "should create cookie if device exists" do
      cookies[:kolide_device_id] = device.id
      get "/"
      expect(response.cookies["kolide_non_onboarded"]).to be_nil
    end
  end
end
