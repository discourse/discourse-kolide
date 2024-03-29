# frozen_string_literal: true

module ::Kolide
  class GroupAlert
    attr_accessor :post, :devices, :group, :last_reminded_at_field

    REMINDER_NAME = "Kolide Alert"
    REMINDER_INTERVAL = 1.days

    def initialize
      @group = Group.find_by(name: SiteSetting.kolide_admin_group_name)
      post_id_field =
        GroupCustomField.find_or_initialize_by(name: "kolide_alert_post_id", group_id: group.id)
      @last_reminded_at_field =
        GroupCustomField.find_or_initialize_by(
          name: "kolide_alert_last_reminded_at",
          group_id: group.id,
        )

      @devices = Device.where(user_id: nil)
      @post = Post.find_by(id: post_id_field.value) if post_id_field.present?

      if post_id_field.blank? || @post&.topic.blank?
        create_post!
        post_id_field.update!(value: @post.id) if @post.present?
      end
    end

    def remind!
      update_post_body

      if devices.count == 0
        Notification
          .where(notification_type: Notification.types[:topic_reminder])
          .where("data::json ->> 'reminder_name' = '#{REMINDER_NAME}'")
          .destroy_all
        return
      end

      return if last_reminded_at.present? && last_reminded_at > REMINDER_INTERVAL.ago

      group.users.each do |user|
        Notification.consolidate_or_create!(
          user_id: user.id,
          notification_type: Notification.types[:topic_reminder],
          topic_id: post.topic_id,
          post_number: post.post_number,
          data: {
            display_username: user.username,
            topic_title: topic_title,
            reminder_name: REMINDER_NAME,
          }.to_json,
        )
      end
      set_last_reminded_at(Time.now)
    end

    def topic_title
      I18n.t("kolide.group_alert.title", count: devices.count)
    end

    def last_reminded_at
      (last_reminded_at_field.value.presence || "").to_datetime
    end

    def self.notification_consolidation_plan
      ::Notifications::DeletePreviousNotifications.new(type: Notification.types[:topic_reminder])
    end

    private

    def update_post_body
      body = post_body
      if post.raw != body
        revisor = PostRevisor.new(post)
        revisor.revise!(Discourse.system_user, { raw: body }, skip_validations: true)
      end

      title = topic_title
      topic = post.topic
      if title != topic.title
        topic.title = title
        topic.save!
      end
    end

    def create_post!
      return unless devices.exists?

      @post =
        PostCreator.create!(
          Discourse.system_user,
          title: topic_title,
          raw: post_body,
          archetype: Archetype.private_message,
          target_group_names: group.name,
          validate: false,
        )

      set_last_reminded_at(post.created_at)
      @post
    end

    def post_body
      return I18n.t("kolide.group_alert.no_issues") unless devices.exists?

      rows = []
      devices.each do |device|
        url = "https://k2.kolide.com/x/inventory/devices/#{device.uid}"
        user = UserIpAddressHistory.find_by(ip_address: device.ip_address.to_s)&.user
        user_info =
          (
            if user.present?
              " (@#{user.username} [kolide-assign user=#{user.id} device=#{device.id}])"
            else
              ""
            end
          )
        rows << "| [#{device.uid}](#{url}) | #{device.name} | #{device.hardware_model} | #{device.ip_address}#{user_info} |"
      end

      I18n.t("kolide.group_alert.body", rows: rows.join("\n"))
    end

    def set_last_reminded_at(value)
      last_reminded_at_field.value = value
      last_reminded_at_field.save!
    end
  end
end
