# frozen_string_literal: true

module Kolide::ApplicationControllerExtension
  def self.prepended(base)
    base.class_eval { base.after_action :ensure_device_onboarded }

    protected

    def ensure_device_onboarded
      return unless SiteSetting.kolide_enabled?
      return if current_user.blank? || cookies[:kolide_onboarded].present?
      return if (request.format && request.format.json?) || request.xhr?
      return if MobileDetection.mobile_device?(request.user_agent)

      user_auth_token = current_user.user_auth_tokens.find_by(auth_token: guardian.auth_token)
      return if user_auth_token.blank?

      ips = [request.ip, user_auth_token.client_ip]
      ips +=
        current_user
          .user_auth_token_logs
          .where(user_auth_token_id: user_auth_token.id)
          .where("created_at > ?", 20.days.ago)
          .distinct
          .pluck(:client_ip)

      if current_user.kolide_devices.exists?(ip_address: ips.uniq)
        cookies[:kolide_onboarded] = { value: true, expires: 1.month.from_now }
      end
    end
  end
end
