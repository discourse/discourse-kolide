# frozen_string_literal: true

class CreateKolideTables < ActiveRecord::Migration[6.0]
  def change
    create_table :kolide_devices do |t|
      t.integer :uid, null: false, index: true, unique: true
      t.integer :user_id, null: true
      t.string :name
      t.string :primary_user_name
      t.string :hardware_model
      t.timestamps
    end

    create_table :kolide_issues do |t|
      t.integer :uid, null: false, index: true, unique: true
      t.integer :device_id, null: false
      t.string :title, null: false
      t.boolean :ignored, null: false, default: false
      t.boolean :resolved, null: false, default: false
      t.datetime :reported_at, null: true
      t.datetime :resolved_at, null: true
      t.timestamps
    end
  end
end
