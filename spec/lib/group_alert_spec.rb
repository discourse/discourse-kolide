# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Kolide::GroupAlert do

  let(:group) { Fabricate(:group) }
  let(:device) { Fabricate(:kolide_device, user: nil) }

  before do
    SiteSetting.kolide_enabled = true
    SiteSetting.kolide_api_key = "KOLIDE_API_KEY"
    SiteSetting.kolide_admin_group_name = group.name
  end

  it "creates a group PM if unassigned devices are present" do
    device
    freeze_time

    alert = nil
    group_pms = Topic.joins(:topic_allowed_groups).where("topic_allowed_groups.group_id = ?", group.id)
    expect { alert = described_class.new }.to change { group_pms.count }.by(1)

    pm = group_pms.first
    expect(pm.title).to eq(I18n.t('kolide.group_alert.title', count: 1))
    expected_row = "| [#{device.uid}](https://k2.kolide.com/x/inventory/devices/#{device.uid}) | #{device.name} | #{device.hardware_model} | #{device.ip_address} |"
    expect(pm.first_post.raw).to eq(I18n.t('kolide.group_alert.body', rows: expected_row).strip)
  end

  it "will match the corresponding user by IP address" do
    SiteSetting.keep_old_ip_address_count = 10
    user = Fabricate(:user)
    user.update_ip_address!(device.ip_address.to_s)
    user.reload

    freeze_time

    group_pms = Topic.joins(:topic_allowed_groups).where("topic_allowed_groups.group_id = ?", group.id)
    described_class.new

    pm = group_pms.first
    expected_row = "| [#{device.uid}](https://k2.kolide.com/x/inventory/devices/#{device.uid}) | #{device.name} | #{device.hardware_model} | #{user.ip_address} (@#{user.username} [kolide-assign user=#{user.id} device=#{device.id}]) |"
    expect(pm.first_post.raw).to eq(I18n.t('kolide.group_alert.body', rows: expected_row).strip)
  end

end
