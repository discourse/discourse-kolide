# frozen_string_literal: true

class Kolide::DeviceSerializer < ApplicationSerializer
  attributes :id, :name, :hardware_model, :is_orphan

  def is_orphan
    object.user_id.nil?
  end
end
