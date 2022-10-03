# frozen_string_literal: true

require 'rails_helper'
require_relative '../spec_helper'

describe ::Kolide::Check do
  include_context "with kolide spec helper"

  api_url = "#{::Kolide::Api::BASE_URL}checks?per_page=500"

  before do
    SiteSetting.kolide_enabled = true
    SiteSetting.kolide_api_key = "KOLIDE_API_KEY"
    content = { status: 200, headers: { "Content-Type" => "application/json" } }

    checks = content.merge(body: get_kolide_response('checks.json'))
    stub_request(:get, api_url).to_return(checks)
  end

  it "syncs Kolide checks from API endpoint" do
    expect { ::Kolide::Check.sync_all! }.to change { ::Kolide::Check.count }.by(25)
    expect(::Kolide::Check.pluck(:delay).uniq).to contain_exactly(0, 48, 24)
  end

end
