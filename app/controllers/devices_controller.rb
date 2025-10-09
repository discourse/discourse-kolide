# frozen_string_literal: true

module ::Kolide
  class DevicesController < ::ApplicationController
    requires_plugin Kolide::PLUGIN_NAME
    requires_login

    def index
      render_devices
    end

    def current
      device_id = params[:device_id]
      is_mobile = params[:is_mobile]

      raise Discourse::NotFound if device_id.blank? && is_mobile.blank?

      if is_mobile.present?
        cookies.permanent[:kolide_device_id] = "mobile"
      else
        device = Device.find_by(id: device_id)
        return render json: failed_json, status: :unprocessable_content if device.blank?

        cookies.permanent[:kolide_device_id] = device.id
      end

      cookies.delete(:kolide_non_onboarded)
      render json: success_json, status: :ok
    end

    def refresh
      Device.sync_all!
      render_devices
    end

    def assign
      params.require(:user_id)
      params.require(:device_id)

      admin_group = SiteSetting.kolide_admin_group_name
      if !current_user.admin? &&
           (admin_group.blank? || !current_user.groups.where(name: admin_group).exists?)
        raise Discourse::NotFound
      end

      user = User.find(params[:user_id])
      device = Device.find(params[:device_id])
      kolide_person_id = user.custom_fields["kolide_person_id"]
      kolide_device_id = device.uid

      payload = { owner_id: kolide_person_id, owner_type: "Person" }
      if SiteSetting.kolide_verbose_log
        Rails.logger.warn("Kolide verbose log:\n Payload = #{payload.inspect}")
      end
      response = Kolide.api.put("devices/#{kolide_device_id}/owner", payload)
      return render json: failed_json, status: :unprocessable_content if response[:error].present?

      device.update(user_id: user.id)
      render json: success_json, status: :ok
    end

    private

    def render_devices
      devices = Device.where(user_id: [nil, current_user.id]).order("user_id DESC NULLS LAST, name")
      render_serialized(devices, DeviceSerializer)
    end
  end
end
