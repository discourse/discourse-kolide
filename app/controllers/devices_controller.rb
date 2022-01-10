# frozen_string_literal: true

module ::Kolide

  class DevicesController < ::ApplicationController
    requires_login

    def assign
      params.require(:user_id)
      params.require(:device_id)

      user = User.find(params[:user_id])
      device = Device.find(params[:device_id])
      kolide_person_id = user.custom_fields["kolide_person_id"]
      kolide_device_id = device.uid

      response = Kolide.api.put("devices/#{kolide_device_id}/owner", owner_id: kolide_person_id, owner_type: "Person")
      return if response[:error].present?

      render body: nil, status: 200
    end
  end
end
