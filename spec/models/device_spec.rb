# frozen_string_literal: true

require 'rails_helper'
require_relative '../spec_helper'

describe ::Kolide::Device do
  include_context "spec helper"

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

end
