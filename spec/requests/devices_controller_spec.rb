# frozen_string_literal: true

require "rails_helper"
require_relative "../spec_helper"

RSpec.describe ::Kolide::DevicesController do
  include_context "with kolide spec helper"

  fab!(:group)
  fab!(:kolide_admin, :user)
  fab!(:user)
  fab!(:device) { Fabricate(:kolide_device, user: nil) }
  fab!(:user_device) { Fabricate(:kolide_device, user: user) }
  fab!(:device2, :kolide_device)

  describe "index" do
    it "returns a list of devices for a user" do
      sign_in(user)

      device
      device2
      user_device

      get "/kolide/devices.json"

      expect(response.status).to eq(200)
      devices = response.parsed_body
      expect(devices.length).to eq(2)
      expect(devices.pluck("id")).to contain_exactly(device.id, user_device.id)
    end
  end

  describe "current" do
    it "sets the current device id in a cookie" do
      sign_in(user)

      post "/kolide/devices/current.json", params: { device_id: device.id }

      expect(response.status).to eq(200)
      expect(response.cookies["kolide_device_id"]).to eq(device.id.to_s)
    end

    it "sets the current device id in a cookie for mobile" do
      sign_in(user)

      post "/kolide/devices/current.json", params: { is_mobile: true }

      expect(response.status).to eq(200)
      expect(response.cookies["kolide_device_id"]).to eq("mobile")
    end
  end

  describe "refresh" do
    it "refreshes the device data" do
      sign_in(user)
      ::Kolide::Device.expects(:sync_all!).once

      put "/kolide/devices/refresh.json"

      expect(response.status).to eq(200)
      devices = response.parsed_body
      expect(devices.length).to eq(2)
      expect(devices.pluck("id")).to contain_exactly(device.id, user_device.id)
    end
  end

  describe "assign" do
    before do
      user.custom_fields["kolide_person_id"] = "98765"
      user.save_custom_fields
      stub_request(:put, "#{::Kolide::Api::BASE_URL}devices/#{device.uid}/owner")
        .with do |req|
          data = JSON.parse(req.body.to_s)
          expect(data["owner_id"]).to eq("98765")
          expect(req.headers["Content-Type"]).to eq("application/json")
        end
        .to_return(status: 200, body: "{}", headers: {})
    end

    it "updates the owner of the device in both Kolide and Discourse" do
      sign_in(kolide_admin)

      put "/kolide/devices/#{device.id}/assign.json", params: { user_id: user.id }

      expect(response.status).to eq(404)

      SiteSetting.kolide_admin_group_name = group.name
      group.add(kolide_admin)

      put "/kolide/devices/#{device.id}/assign.json", params: { user_id: user.id }

      expect(response.status).to eq(200)
      expect(device.reload.user_id).to eq(user.id)
    end
  end
end
