# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Kolide::UserAlert do
  let(:user) { Fabricate(:user) }
  let(:device) { Fabricate(:kolide_device, user: user) }
  let(:check) { Fabricate(:kolide_check) }
  let(:issue) { Fabricate(:kolide_issue, device: device, check: check) }

  before do
    SiteSetting.kolide_enabled = true
    SiteSetting.kolide_api_key = "KOLIDE_API_KEY"
  end

  it "creates a PM with issues and a notification" do
    freeze_time

    issue
    alert = nil
    expect { alert = ::Kolide::UserAlert.new(user) }.to change {
      Topic.private_messages_for_user(user).count
    }.by(1)

    pm = Topic.private_messages_for_user(user).last
    post = pm.first_post
    expect(pm.title).to eq(I18n.t("kolide.alert.title", count: 1, username: user.username))
    expect(post.raw).to include("[^#{issue.id}]: user: deviceuser")

    freeze_time 1.hour.from_now
    expect { alert.remind! }.not_to change { user.notifications.count }

    freeze_time 1.day.from_now
    expect { alert.remind! }.to change { user.notifications.count }.by(1)

    user.notifications.last.destroy!
    freeze_time 1.hour.from_now
    expect { alert.remind! }.not_to change { user.notifications.count }

    ::Kolide::Issue.update_all(resolved: true)
    ::Kolide::UserAlert.new(user).remind!
    post.reload
    expect(post.raw).to eq(I18n.t("kolide.alert.no_issues"))
  end

  it "skips reminder notification based on check delay" do
    freeze_time

    issue
    check.update(delay: 3 * 24)
    alert = ::Kolide::UserAlert.new(user)

    freeze_time 1.day.from_now
    expect { alert.remind! }.not_to change { user.notifications.count }

    freeze_time 2.days.from_now
    expect { alert.remind! }.to change { user.notifications.count }.by(1)
  end

  it "shows upcoming issues when there are no open issues" do
    freeze_time

    upcoming_issue =
      Fabricate(
        :kolide_issue,
        device: device,
        resolved: false,
        ignored: false,
        reported_at: Time.now,
        check: check,
      )
    check.update(delay: 3 * 24) # Upcoming issue delay

    alert = ::Kolide::UserAlert.new(user)

    pm = Topic.private_messages_for_user(user).last
    post = pm.first_post

    expect(post.raw).to include(
      "| #{device.name} | #{device.hardware_model} | #{upcoming_issue.markdown} | [#{upcoming_issue.reported_at.strftime("date=%Y-%m-%d time=%H:%M:%S")} timezone='UTC' format='L LT'] |",
    )
  end

  it "includes 1 open issue, 1 upcoming issue, and 1 resolved issue in the post body" do
    freeze_time

    open_issue =
      Fabricate(
        :kolide_issue,
        device: device,
        resolved: false,
        ignored: false,
        reported_at: 2.days.ago,
      )
    upcoming_issue =
      Fabricate(
        :kolide_issue,
        device: device,
        resolved: false,
        ignored: false,
        reported_at: Time.now,
        check: check,
      )
    check.update(delay: 3 * 24) # Upcoming issue delay
    resolved_issue =
      Fabricate(
        :kolide_issue,
        device: device,
        resolved: true,
        ignored: false,
        resolved_at: 1.day.ago,
      )

    alert = ::Kolide::UserAlert.new(user)

    pm = Topic.private_messages_for_user(user).last
    post = pm.first_post

    expect(post.raw).to include(
      "| #{device.name} | #{device.hardware_model} | #{open_issue.markdown} | [#{open_issue.reported_at.strftime("date=%Y-%m-%d time=%H:%M:%S")} timezone='UTC' format='L LT'] |",
    )
    expect(post.raw).to include(
      "| #{device.name} | #{device.hardware_model} | #{upcoming_issue.markdown} | [#{upcoming_issue.reported_at.strftime("date=%Y-%m-%d time=%H:%M:%S")} timezone='UTC' format='L LT'] |",
    )
    expect(post.raw).to include(
      "| #{device.name} | #{device.hardware_model} | #{resolved_issue.title} | [#{resolved_issue.resolved_at.strftime("date=%Y-%m-%d time=%H:%M:%S")} timezone='UTC' format='L LT'] |",
    )
  end

  it "removes the notification if all the issues are resolved" do
    freeze_time

    issue
    user2 = Fabricate(:user)
    device2 = Fabricate(:kolide_device, user: user2)
    issue2 = Fabricate(:kolide_issue, device: device2, check: check)

    alert = ::Kolide::UserAlert.new(user)
    alert2 = ::Kolide::UserAlert.new(user2)

    freeze_time 1.day.from_now
    alert.remind!
    alert2.remind!

    expect(user.notifications.count).to eq(1)
    expect(user2.notifications.count).to eq(1)

    issue.update(resolved: true)

    alert.remind!
    alert2.remind!

    expect(user.notifications.count).to eq(0)
    expect(user2.notifications.count).to eq(1)
  end

  context "for polymorphic bookmarks" do
    it "creates a PM with issues and a notification" do
      freeze_time

      issue
      alert = nil
      expect { alert = ::Kolide::UserAlert.new(user) }.to change {
        Topic.private_messages_for_user(user).count
      }.by(1)

      pm = Topic.private_messages_for_user(user).last
      post = pm.first_post
      expect(pm.title).to eq(I18n.t("kolide.alert.title", count: 1, username: user.username))
      expected_row = <<~RAW
      | #{device.name} | #{device.hardware_model} | #{issue.markdown} | [#{issue.reported_at.strftime("date=%Y-%m-%d time=%H:%M:%S")} timezone='UTC' format='L LT'] |
      RAW
      expect(post.raw).to include(expected_row)
      expect(post.raw).to include("[^#{issue.id}]: user: deviceuser")

      freeze_time 1.hour.from_now
      expect { alert.remind! }.not_to change { user.notifications.count }

      freeze_time 1.day.from_now
      expect { alert.remind! }.to change { user.notifications.count }.by(1)
      expect(user.notifications.last.created_at).to eq_time(Time.zone.now)

      freeze_time 3.days.from_now
      expect { alert.remind! }.not_to change { user.notifications.count }
      expect(user.notifications.last.created_at).to eq_time(Time.zone.now)

      user.notifications.last.destroy!
      freeze_time 1.hour.from_now
      expect { alert.remind! }.not_to change { user.notifications.count }

      ::Kolide::Issue.update_all(resolved: true)
      ::Kolide::UserAlert.new(user).remind!
      post.reload
      expect(post.raw).to eq(I18n.t("kolide.alert.no_issues"))
    end

    it "skips reminder notification based on check delay" do
      freeze_time

      issue
      check.update(delay: 3 * 24)
      alert = ::Kolide::UserAlert.new(user)

      freeze_time 1.day.from_now
      expect { alert.remind! }.not_to change { user.notifications.count }

      freeze_time 2.days.from_now
      expect { alert.remind! }.to change { user.notifications.count }.by(1)
    end
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
