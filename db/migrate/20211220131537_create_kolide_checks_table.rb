# frozen_string_literal: true

class CreateKolideChecksTable < ActiveRecord::Migration[6.0]
  def change
    create_table :kolide_checks do |t|
      t.integer :uid, null: false, index: true, unique: true
      t.string :name
      t.string :display_name
      t.string :description
      t.integer :delay, default: 0
      t.integer :failing_device_count, default: 0
      t.timestamps
    end
  end
end
