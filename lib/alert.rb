# frozen_string_literal: true

module ::Kolide

  class Alert
    attr_accessor :post, :issues, :user

    REMINDER_NAME = "Kolide Device Issues"

    def initialize(user)
      @user = user
      custom_field = UserCustomField.find_or_initialize_by(name: "kolide_alert_post_id", user_id: user.id)

      @issues = Issue.joins(:device).where("kolide_devices.user_id = ?", user.id)
      @post = Post.find_by(id: custom_field.value) if custom_field.present?
      
      if custom_field.blank? || @post.blank?
        @post = create_post!
        custom_field.value = @post.id
        custom_field.save!
      end
    end

    def remind!
      update_reminder_body
      bookmark_manager = BookmarkManager.new(user)
      bookmark_id = Bookmark.where(user_id: user.id, post_id: post.id, name: REMINDER_NAME).pluck(:id).first
      return if bookmark_id.present?

      bookmark_manager.create(
        post_id: post.id,
        name: REMINDER_NAME,
        reminder_at: 5.minutes.from_now,
        options: {
          auto_delete_preference: Bookmark.auto_delete_preferences[:when_reminder_sent]
        }
      )
    end

    private

    def update_reminder_body
      post.raw = reminder_body
      post.save!
      post.rebake!

      topic = post.topic
      topic.title = I18n.t('kolide.alert.title', count: open_issues.count)
      topic.save!
    end

    def create_post!
      return unless issues.exists?
      title = I18n.t('kolide.alert.title', count: open_issues.count)

      PostCreator.create!(
        Discourse.system_user,
        title: title,
        raw: reminder_body,
        archetype: Archetype.private_message,
        target_usernames: user.username,
        validate: false
      )
    end

    def reminder_body
      return unless issues.exists?

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
        rows << "| #{device.name} | #{device.primary_user_name} | #{device.hardware_model} | #{issue.title} | #{issue.reported_at} |"
      end

      I18n.t("kolide.alert.#{key}_issues", rows: rows.join("\n"))
    end

    def open_issues
      issues.where(resolved: false, ignored: false)
    end
  end
end
