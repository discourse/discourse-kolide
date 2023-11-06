# frozen_string_literal: true

module Kolide::ApplicationControllerExtension
  def self.prepended(base)
    base.class_eval { base.before_action :ensure_device_onboarded }

    def ensure_device_onboarded
      return unless SiteSetting.kolide_enabled?
      return if current_user.blank? || current_user.kolide_id.blank?
      return if (request.format && request.format.json?) || request.xhr? || !request.get?
      return if MobileDetection.mobile_device?(request.user_agent)

      user_auth_token = current_user.user_auth_tokens.find_by(auth_token: guardian.auth_token)
      return if user_auth_token.blank?

      device_id = cookies[:kolide_device_id]
      if device_id.present? 
        if ::Kolide::Device.where(id: device_id.to_i, user_id: [nil, current_user.id]).exists?
          cookies.delete(:kolide_non_onboarded)
        else
          cookies.delete(:kolide_device_id)
        end
      end
    end
  end
end
