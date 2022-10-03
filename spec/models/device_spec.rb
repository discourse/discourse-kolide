# frozen_string_literal: true

require 'rails_helper'
require_relative '../spec_helper'

describe ::Kolide::Device do
  include_context "with kolide spec helper"

  api_url = "#{::Kolide::Api::BASE_URL}devices?per_page=500"

  before do
    content = { status: 200, headers: { "Content-Type" => "application/json" } }

    devices = content.merge(body: get_kolide_response('devices.json'))
    stub_request(:get, api_url).to_return(devices)
  end

  it "syncs Kolide devices from API endpoint" do
    device = Fabricate(:kolide_device)
    issue = Fabricate(:kolide_issue, device: device)
    expect { ::Kolide::Device.sync_all! }.to change { ::Kolide::Device.count }.by(1)
    expect { device.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { issue.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe "#destroy" do
    fab!(:device) { Fabricate(:kolide_device) }

    before do
      issue = Fabricate(:kolide_issue, device: device)
      ::Kolide::UserAlert.new(device.user).remind!
    end

    it "updates user alert PM" do
      post = Topic.last.first_post
      expect(post.raw).to include("Screen Lock Disabled")

      device.destroy

      expect(post.reload.raw).to include(I18n.t("kolide.group_alert.no_issues"))
    end

    it "skips PM update if user not found" do
      ::Kolide::UserAlert.any_instance.expects(:remind!).never

      device.user.destroy
      device.reload.destroy
    end
  end

end
