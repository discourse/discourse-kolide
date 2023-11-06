# frozen_string_literal: true

module Kolide
  class DeviceAuthToken < ::ActiveRecord::Base
    self.table_name = "kolide_device_auth_tokens"

    belongs_to :device, class_name: "Kolide::Device"
    belongs_to :user_auth_token
  end
end
