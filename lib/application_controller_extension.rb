# frozen_string_literal: true

module Kolide::ApplicationControllerExtension
  def self.prepended(base)
    base.class_eval { base.before_action :ensure_device_onboarded }

    protected

    def ensure_device_onboarded
      return unless SiteSetting.kolide_enabled?
      return if current_user.blank? || current_user.kolide_id.blank?
      return if (request.format && request.format.json?) || request.xhr? || !request.get?
      return if MobileDetection.mobile_device?(request.user_agent)

      user_auth_token = current_user.user_auth_tokens.find_by(auth_token: guardian.auth_token)
      return if user_auth_token.blank?

      device_id = cookies[:kolide_device_id]
      if device_id.present? 
        if current_user.kolide_devices.exists?(device_id.to_i)
          cookies.delete(:kolide_non_onboarded)
          return
        else
          cookies.delete(:kolide_device_id)
        end
      end

      enforce_at = cookies[:kolide_non_onboarded]

      if enforce_at.present?
        enforce_at = Time.at(enforce_at.to_i)
      else
        enforce_at = SiteSetting.kolide_onboarding_grace_period_days.days.from_now
        cookies[:kolide_non_onboarded] = {
          value: enforce_at.to_i,
          expires: 1.year.from_now
        }
      end

      return if enforce_at.future?

      redirect_path = path("/u/#{current_user.encoded_username}/preferences/kolide")
      return if request.fullpath.start_with?(redirect_path)

      redirect_to path(redirect_path)
      nil
    end
  end
end
