# frozen_string_literal: true

module ::Kolide
  class DevicesController < ::ApplicationController
    requires_plugin Kolide::PLUGIN_NAME
    requires_login

    def index
      render_serialized(current_user.kolide_devices, KolideDeviceSerializer)
    end

    def assign
      params.require(:user_id)
      params.require(:device_id)

      admin_group = SiteSetting.kolide_admin_group_name
      unless current_user.admin? ||
               (admin_group.present? && current_user.groups.where(name: admin_group).exists?)
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
      return render json: failed_json, status: 422 if response[:error].present?

      device.update(user_id: user.id)
      render json: success_json, status: 200
    end
  end
end
