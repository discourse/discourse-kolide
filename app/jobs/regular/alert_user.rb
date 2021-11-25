# frozen_string_literal: true

module Jobs
  class AlertUser < ::Jobs::Base
    sidekiq_options queue: 'low'

    def execute(args)
      user = User.find_by(id: args[:user_id])
      raise Discourse::InvalidParameters.new(:user_id) if user.nil?

      ::Kolide::Alert.new.remind(user)
    end
  end
end
