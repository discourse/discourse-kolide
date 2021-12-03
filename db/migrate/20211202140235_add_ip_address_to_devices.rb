# frozen_string_literal: true

class AddIpAddressToDevices < ActiveRecord::Migration[6.1]
  def up
    add_column :kolide_devices, :ip_address, :inet
  end

  def down
    remove_column :kolide_devices, :ip_address
  end
end
