# frozen_string_literal: true

module ::Kolide

  class Alert

    def remind(user)
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

    private

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

      I18n.t("pending_assigns_reminder.#{key}", items.symbolize_keys!)
    end

    def time_in_words_for(topic)
      FreedomPatches::Rails4.distance_of_time_in_words(
        Time.zone.now, topic.assigned_at.to_time, false, scope: 'datetime.distance_in_words_verbose'
      )
    end

    def frequency_in_words(user)
      frequency = if user.custom_fields&.has_key?(REMINDERS_FREQUENCY)
        user.custom_fields[REMINDERS_FREQUENCY]
      else
        SiteSetting.remind_assigns_frequency
      end

      ::RemindAssignsFrequencySiteSettings.frequency_for(frequency)
    end
  end
end
