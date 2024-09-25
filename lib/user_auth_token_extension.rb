# frozen_string_literal: true

module Kolide::UserAuthTokenExtension
  def self.prepended(base)
    base.has_many :kolide_device_auth_tokens, dependent: :destroy, class_name: "Kolide::DeviceAuthToken"
  end
end
