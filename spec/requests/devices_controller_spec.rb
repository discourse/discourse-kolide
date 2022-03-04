# frozen_string_literal: true

require "rails_helper"
require_relative '../spec_helper'

RSpec.describe ::Kolide::DevicesController do
  include_context "spec helper"

  fab!(:group) { Fabricate(:group) }
  fab!(:kolide_admin) { Fabricate(:user) }
  fab!(:user) { Fabricate(:user) }
  fab!(:device) { Fabricate(:kolide_device, user: nil) }

  context "assign" do
    before do
      user.custom_fields["kolide_person_id"] = "98765"
      user.save_custom_fields
      stub_request(:put, "#{::Kolide::Api::BASE_URL}devices/#{device.uid}/owner").with do |req|
        data = JSON.parse(req.body.to_s)
        expect(data["owner_id"]).to eq("98765")
        expect(req.headers["Content-Type"]).to eq("application/json")
      end.to_return(status: 200, body: "{}", headers: {})
    end

    it 'updates the owner of the device in both Kolide and Discourse' do
      sign_in(kolide_admin)

      put "/kolide/devices/#{device.id}/assign.json", params: {
        user_id: user.id
      }

      expect(response.status).to eq(404)

      SiteSetting.kolide_admin_group_name = group.name
      group.add(kolide_admin)

      put "/kolide/devices/#{device.id}/assign.json", params: {
        user_id: user.id
      }

      expect(response.status).to eq(200)
      expect(device.reload.user_id).to eq(user.id)
    end
  end
end
