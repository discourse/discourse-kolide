# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Kolide::GroupAlert do

  let(:group) { Fabricate(:group) }

  before do
    SiteSetting.kolide_enabled = true
    SiteSetting.kolide_api_key = "KOLIDE_API_KEY"
    SiteSetting.kolide_admin_group_name = group.name
  end

  it "" do
    device = ::Kolide::Device.create!(
      uid: "12345",
      name: "My Mac",
      primary_user_name: "deviceadmin",
      hardware_model: "Macbook",
      ip_address: "127.0.0.1"
    )

    freeze_time

    alert = nil
    group_pms = Topic.joins(:topic_allowed_groups).where("topic_allowed_groups.group_id = ?", group.id)
    expect { alert = described_class.new }.to change { group_pms.count }.by(1)

    pm = group_pms.first
    expect(pm.title).to eq(I18n.t('kolide.group_alert.title', count: 1))
    expected_row = "| [12345](https://k2.kolide.com/my/inventory/devices/12345) | My Mac | deviceadmin | Macbook | 127.0.0.1 |"
    expect(pm.first_post.raw).to eq(I18n.t('kolide.group_alert.body', rows: expected_row).strip)
  end

end
