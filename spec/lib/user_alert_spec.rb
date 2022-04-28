# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Kolide::UserAlert do

  let(:user) { Fabricate(:user) }
  let(:device) { Fabricate(:kolide_device, user: user) }
  let(:check) { Fabricate(:kolide_check) }
  let(:issue) { Fabricate(:kolide_issue, device: device, check: check) }

  before do
    SiteSetting.kolide_enabled = true
    SiteSetting.kolide_api_key = "KOLIDE_API_KEY"
  end

  it "creates a PM with issues and a bookmark" do
    freeze_time

    issue
    alert = nil
    expect { alert = ::Kolide::UserAlert.new(user) }.to change { Topic.private_messages_for_user(user).count }.by(1)

    pm = Topic.private_messages_for_user(user).last
    post = pm.first_post
    expect(pm.title).to eq(I18n.t('kolide.alert.title', count: 1, username: user.username))
    expect(post.raw).to include("[^#{issue.id}]: user: deviceuser")

    freeze_time 1.hour.from_now
    expect { alert.remind! }.to change { user.bookmarks.count }.by(0)

    freeze_time 1.day.from_now
    expect { alert.remind! }.to change { user.bookmarks.count }.by(1)

    user.bookmarks.last.destroy!
    freeze_time 1.hour.from_now
    expect { alert.remind! }.to change { user.bookmarks.count }.by(0)

    ::Kolide::Issue.update_all(resolved: true)
    ::Kolide::UserAlert.new(user).remind!
    post.reload
    expect(post.raw).to eq(I18n.t("kolide.alert.no_issues"))
  end

  it "skips bookmark reminder based on check delay" do
    freeze_time

    issue
    check.update(delay: 3 * 24)
    alert = ::Kolide::UserAlert.new(user)

    freeze_time 1.day.from_now
    expect { alert.remind! }.to change { user.bookmarks.count }.by(0)

    freeze_time 2.days.from_now
    expect { alert.remind! }.to change { user.bookmarks.count }.by(1)
  end

  it "adds Kolide helpers group to PM" do
    issue
    group = Fabricate(:group)
    SiteSetting.kolide_helpers_group_name = group.name

    ::Kolide::UserAlert.new(user)

    pm = Topic.private_messages_for_user(user).last
    expect(pm.topic_allowed_groups.pluck(:group_id)).to include(group.id)
  end

end
