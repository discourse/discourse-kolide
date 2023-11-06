# frozen_string_literal: true

class CreateDeviceAuthTokensTable < ActiveRecord::Migration[6.0]
  def change
    create_table :kolide_device_auth_tokens do |t|
      t.integer :device_id, null: false, index: true
      t.integer :user_auth_token_id, null: false, index: true
      t.timestamps
    end
  end
end
