# frozen_string_literal: true

module ::Kolide

  class Alert
    attr_accessor :post

    def initialize(user)
      custom_field = UserCustomField.find_or_initialize_by(name: "kolide_alert_post_id", user_id: user.id)
      
      if custom_field.blank?
        @post = create_post!
        custom_field.value = @post.id
        custom_field.save!
      else
        @post = Post.find_by(id: custom_field.value)
      end
    end

    def remind!
    end

    private

    def create_post!
      title = I18n.t('kolide.alert.title', count: 0)

      PostCreator.create!(
        Discourse.system_user,
        title: title,
        raw: reminder_body(user, assigned_topics_count, newest_topics, oldest_topics),
        archetype: Archetype.private_message,
        target_usernames: user.username,
        validate: false
      )
    end

    def reminder_body(user, assigned_topics_count, first_three_topics, last_three_topics)
      newest_list = build_list_for(:newest, first_three_topics)
      oldest_list = build_list_for(:oldest, last_three_topics)

      I18n.t(
        'kolide.alert.body',
        pending_assignments: assigned_topics_count,
        assignments_link: "#{Discourse.base_url}/u/#{user.username_lower}/activity/assigned",
        newest_assignments: newest_list,
        oldest_assignments: oldest_list,
        frequency: frequency_in_words(user)
      )
    end

    def build_list_for(key, topics)
      return '' if topics.empty?
      initial_list = { 'topic_0' => '', 'topic_1' => '', 'topic_2' => '' }
      items = topics.each_with_index.reduce(initial_list) do |memo, (t, index)|
        memo["topic_#{index}"] = "- [#{Emoji.gsub_emoji_to_unicode(t.fancy_title)}](#{t.relative_url}) - assigned #{time_in_words_for(t)}"
        memo
      end

      I18n.t("kolide.alert.#{key}", items.symbolize_keys!)
    end
  end
end
