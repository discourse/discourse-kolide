# frozen_string_literal: true

module Kolide::ApplicationControllerExtension
  def self.prepended(base)
    base.class_eval { base.before_action :ensure_device_onboarded }

    def ensure_device_onboarded
      unless requires_kolide_onboarding?
        cookies.delete(:kolide_non_onboarded)
        return
      end

      return if request.format&.json? || request.xhr? || !request.get?

      user_auth_token = current_user.user_auth_tokens.find_by(auth_token: guardian.auth_token)
      return if user_auth_token.blank?

      device_id = cookies[:kolide_device_id]
      if device_id.present?
        if ::Kolide::Device.where(id: device_id.to_i, user_id: [nil, current_user.id]).exists?
          cookies.delete(:kolide_non_onboarded)
          return
        else
          cookies.delete(:kolide_device_id)
        end
      end

      cookies[:kolide_non_onboarded] = { value: Time.now.to_i, expires: 1.year.from_now }
    end

    def requires_kolide_onboarding?
      return false unless SiteSetting.kolide_enabled?
      return false if current_user.blank?

      user_agent = request.user_agent
      return false if MobileDetection.mobile_device?(user_agent)
      return false if %i[ipad chromebook].include?(BrowserDetection.device(user_agent))

      onboarding_group = SiteSetting.kolide_onboarding_group_name
      onboarding_group.blank? || current_user.groups.exists?(name: onboarding_group)
    end
  end
end
