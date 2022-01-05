# frozen_string_literal: true

require 'rails_helper'

describe 'plugin' do

  let(:user) { Fabricate(:user) }

  before do
    SiteSetting.kolide_enabled = true
    SiteSetting.kolide_api_key = "KOLIDE_API_KEY"
  end

  it 'saves user ip addresses in custom field' do
    old_ip_address = user.ip_address.to_s
    new_ip_address = "127.0.0.10"

    user.ip_address = new_ip_address
    user.save!

    expect(user.custom_fields[User::IP_ADDRESSES_FIELD]).to contain_exactly(old_ip_address, new_ip_address)
  end
end
