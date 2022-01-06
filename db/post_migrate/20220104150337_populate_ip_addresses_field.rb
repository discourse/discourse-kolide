# frozen_string_literal: true

class PopulateIpAddressesField < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      INSERT INTO user_custom_fields (user_id, name, value, created_at, updated_at)
      SELECT id, 'kolide_ip_addresses', host(ip_address), created_at, updated_at
      FROM users
      WHERE ip_address IS NOT NULL
    SQL
  end

  def down
  end
end
