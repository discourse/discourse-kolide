# frozen_string_literal: true

module ::Kolide
  class UserAlert
    attr_accessor :post, :issues, :user, :last_reminded_at_field, :group

    REMINDER_NAME = "Kolide Device Issues"
    REMINDER_INTERVAL = 1.days

    def initialize(user)
      @user = user
      @group = Group.find_by(name: SiteSetting.kolide_helpers_group_name)
      post_id_field =
        UserCustomField.find_or_initialize_by(name: "kolide_alert_post_id", user_id: user.id)
      @last_reminded_at_field =
        UserCustomField.find_or_initialize_by(
          name: "kolide_alert_last_reminded_at",
          user_id: user.id,
        )

      @issues = Issue.joins(:device).where("kolide_devices.user_id = ?", user.id)
      @post = Post.find_by(id: post_id_field.value) if post_id_field.present?

      if post_id_field.blank? || @post.blank?
        create_post!
        post_id_field.update!(value: @post.id) if @post.present?
      end
    end

    def remind!
      return if post.blank?

      update_post_body

      issues_to_remind = open_issues
      if issues_to_remind.blank?
        Notification
          .where(
            user_id: user.id,
            notification_type: Notification.types[:topic_reminder],
            topic_id: post.topic_id,
            post_number: post.post_number,
          )
          .where("data::json ->> 'reminder_name' = '#{REMINDER_NAME}'")
          .destroy_all
        return
      end

      return if last_reminded_at.present? && last_reminded_at > REMINDER_INTERVAL.ago

      notification =
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

      set_last_reminded_at(notification.created_at)
    end

    def topic_title
      I18n.t("kolide.alert.title", count: open_issues.count, username: user.username)
    end

    def last_reminded_at
      (last_reminded_at_field.value.presence || "").to_datetime
    end

    def self.notification_consolidation_plan
      ::Notifications::DeletePreviousNotifications.new(type: Notification.types[:topic_reminder])
    end

    private

    def update_post_body
      new_raw = self.post_body
      if post.raw != new_raw
        revisor = PostRevisor.new(post)
        revisor.revise!(Discourse.system_user, { raw: new_raw }, skip_validations: true)
      end

      topic = post.topic
      topic.title = topic_title
      topic.save! if topic.changed?
    end

    def create_post!
      return unless issues.exists?

      options = {
        title: topic_title,
        raw: post_body,
        archetype: Archetype.private_message,
        target_usernames: user.username,
        validate: false,
      }
      options[:target_group_names] = group.name if group.present?

      @post = PostCreator.create!(Discourse.system_user, options)
      set_last_reminded_at(post.created_at)
      @post
    end

    def post_body
      return I18n.t("kolide.alert.no_issues") unless open_issues.exists? || upcoming_issues.exists?

      open_issues_list = build_list_for(:open)
      upcoming_issues_list = build_list_for(:upcoming)
      resolved_issues_list = build_list_for(:resolved)

      I18n.t(
        "kolide.alert.body",
        open_issues: open_issues_list,
        upcoming_issues: upcoming_issues_list,
        resolved_issues: resolved_issues_list,
      )
    end

    def build_list_for(key)
      if key == :open
        list = open_issues
      elsif key == :upcoming
        list = upcoming_issues
      else
        list = resolved_issues
      end

      return "" unless list.exists?

      rows = []
      footnotes = []
      list
        .includes(:device)
        .each_with_index do |issue, index|
          device = issue.device
          at =
            case key
            when :open
              issue.reported_at
            when :upcoming
              issue.reported_at
            else
              issue.resolved_at
            end
          at =
            "[#{at.strftime("date=%Y-%m-%d time=%H:%M:%S")} timezone='UTC' format='L LT']" if at.present?
          title = issue.title

          if key == :open || key == :upcoming
            title = issue.markdown
            description = ""
            JSON.parse(issue.data).each { |name, value| description += "#{name}: #{value}\n" }

            description = "#{issue.key}: #{issue.value}\n#{description}" if issue.key.present? &&
              issue.value.present?
            footnotes << "#{issue.identifier_markdown}: #{description}"
          end

          rows << "| #{device.name} | #{device.hardware_model} | #{title} | #{at} |"
        end

      I18n.t("kolide.alert.#{key}_issues", rows: rows.join("\n"), footnotes: footnotes.join("\n"))
    end

    def resolved_issues
      issues.where.not(resolved: false, ignored: false).order(updated_at: :desc).limit(20)
    end

    def open_issues
      issues
        .where(resolved: false, ignored: false)
        .joins(:check)
        .where(
          "(#{Time.now.to_i} - EXTRACT(EPOCH FROM kolide_issues.reported_at))/3600 > kolide_checks.delay",
        )
    end

    def upcoming_issues
      issues
        .where(resolved: false, ignored: false)
        .joins(:check)
        .where(
          "(#{Time.now.to_i} - EXTRACT(EPOCH FROM kolide_issues.reported_at))/3600 <= kolide_checks.delay",
        )
    end

    def set_last_reminded_at(value)
      last_reminded_at_field.value = value
      last_reminded_at_field.save!
    end
  end
end
