# frozen_string_literal: true

module ::Kolide

  class UserAlert
    attr_accessor :post, :issues, :user, :last_reminded_at_field

    REMINDER_NAME = "Kolide Device Issues"
    REMINDER_INTERVAL = 1.days

    def initialize(user)
      @user = user
      post_id_field = UserCustomField.find_or_initialize_by(name: "kolide_alert_post_id", user_id: user.id)
      @last_reminded_at_field = UserCustomField.find_or_initialize_by(name: "kolide_alert_last_reminded_at", user_id: user.id)

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
      return if open_issues.count > 0 && last_reminded_at.present? && last_reminded_at > REMINDER_INTERVAL.ago

      bookmark_manager = BookmarkManager.new(user)
      bookmark_id = Bookmark.where(user_id: user.id, post_id: post.id, name: REMINDER_NAME).pluck(:id).first
      return if bookmark_id.present?

      remind_at = 5.minutes.from_now
      bookmark_manager.create(
        post_id: post.id,
        name: REMINDER_NAME,
        reminder_at: remind_at,
        options: {
          auto_delete_preference: Bookmark.auto_delete_preferences[:when_reminder_sent]
        }
      )

      set_last_reminded_at(remind_at)
    end

    def topic_title
      I18n.t('kolide.alert.title', count: open_issues.count)
    end

    def last_reminded_at
      (last_reminded_at_field.value.presence || "").to_datetime
    end

    def self.remind_admins!
      target_group_names = Group.exists?(name: SiteSetting.kolide_admin_group_name) ? SiteSetting.kolide_admin_group_name : nil

      creator = PostCreator.new(Discourse.system_user,
                        title: title,
                        raw: raw,
                        archetype: Archetype.private_message,
                        target_group_names: target_group_names,
                        subtype: TopicSubtype.system_message,
                        skip_validations: true)
    end

    private

    def update_post_body
      new_raw = self.post_body
      if post.raw != new_raw
        revisor = PostRevisor.new(post)
        revisor.revise!(
          Discourse.system_user,
          { raw:  new_raw },
          skip_validations: true
        )
      end

      topic = post.topic
      topic.title = topic_title
      topic.save! if topic.changed?
    end

    def create_post!
      return unless issues.exists?

      @post = PostCreator.create!(
        Discourse.system_user,
        title: topic_title,
        raw: post_body,
        archetype: Archetype.private_message,
        target_usernames: user.username,
        validate: false
      )

      set_last_reminded_at(post.created_at)
      @post
    end

    def post_body
      return I18n.t("kolide.alert.no_issues") unless issues.exists?

      open_issues = build_list_for(:open)
      resolved_issues = build_list_for(:resolved)

      I18n.t(
        'kolide.alert.body',
        open_issues: open_issues,
        resolved_issues: resolved_issues
      )
    end

    def build_list_for(key)
      if key == :open
        list = open_issues
      else
        list = issues.where.not(resolved: false, ignored: false)
      end

      return "" unless list.exists?

      rows = []
      list.includes(:device).each do |issue|
        device = issue.device
        at = (key == :open) ? issue.reported_at : issue.resolved_at
        at = "[#{at.strftime("date=%Y-%m-%d time=%H:%M:%S")} timezone='UTC' format='L LT']" if at.present?
        rows << "| #{device.name} | #{device.primary_user_name} | #{device.hardware_model} | #{issue.title} | #{at} |"
      end

      I18n.t("kolide.alert.#{key}_issues", rows: rows.join("\n"))
    end

    def open_issues
      issues.where(resolved: false, ignored: false)
    end

    def set_last_reminded_at(value)
      last_reminded_at_field.value = value
      last_reminded_at_field.save!
    end
  end
end
