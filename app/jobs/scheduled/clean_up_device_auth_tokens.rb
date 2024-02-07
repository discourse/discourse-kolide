# frozen_string_literal: true

module ::Jobs
  class CleanUpDeviceAuthTokens < ::Jobs::Scheduled
    every 15.minutes

    def execute(args)
      return unless SiteSetting.kolide_enabled && SiteSetting.kolide_api_key

      ::Kolide::DeviceAuthToken
        .joins("LEFT JOIN kolide_device_auth_tokens ON kolide_device_auth_tokens.user_auth_token_id = user_auth_tokens.id")
        .where("user_auth_tokens.id IS NULL")
        .destroy_all
    end
  end
end
