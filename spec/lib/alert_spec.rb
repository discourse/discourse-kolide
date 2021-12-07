# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Kolide::Alert do

  before do
    SiteSetting.kolide_enabled = true
    SiteSetting.kolide_api_key = "KOLIDE_API_KEY"
  end

  let(:user) { Fabricate(:user) }

  it "creates a PM with issues and a bookmark" do
    device = ::Kolide::Device.create!(
      uid: "12345",
      user_id: user.id,
      name: "My Mac",
      primary_user_name: "deviceadmin",
      hardware_model: "Macbook"
    )

    issue = ::Kolide::Issue.create!(
      uid: "23456",
      device_id: device.id,
      title: "Screen Lock Disabled",
      reported_at: 1.days.ago,
      resolved_at: nil
    )

    freeze_time

    alert = nil
    expect { alert = ::Kolide::UserAlert.new(user) }.to change { Topic.private_messages_for_user(user).count }.by(1)

    pm = Topic.private_messages_for_user(user).last
    expect(pm.title).to eq(alert.topic_title)

    freeze_time 1.hour.from_now
    expect { alert.remind! }.to change { user.bookmarks.count }.by(0)

    freeze_time 1.day.from_now
    expect { alert.remind! }.to change { user.bookmarks.count }.by(1)

    user.bookmarks.last.destroy!
    freeze_time 1.hour.from_now
    expect { alert.remind! }.to change { user.bookmarks.count }.by(0)
  end

end
