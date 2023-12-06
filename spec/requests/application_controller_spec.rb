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

    it "deletes cookie if onboarding is not required" do
      cookies[:kolide_non_onboarded] = Time.now.to_i
      get "/",
          headers: {
            "HTTP_USER_AGENT" =>
              "Mozilla/5.0 (X11; CrOS x86_64 11895.95.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.125 Safari/537.36",
          }
      expect(response.cookies["kolide_non_onboarded"]).to be_nil
    end

    it "should create cookie if device exists" do
      cookies[:kolide_device_id] = device.id
      get "/"
      expect(response.cookies["kolide_non_onboarded"]).to be_nil
    end

    it "should create cookie only if member of onboarding group" do
      group = Fabricate(:group, name: "onboarding")
      SiteSetting.kolide_onboarding_group_name = "onboarding"

      get "/"
      expect(response.cookies["kolide_non_onboarded"]).to be_nil

      group.add(user)
      get "/"
      expect(response.cookies["kolide_non_onboarded"]).to eq(Time.now.to_i.to_s)
    end
  end
end
