# frozen_string_literal: true

class AddColumnsToKolideIssues < ActiveRecord::Migration[6.1]
  def change
    add_column :kolide_issues, :key, :string, null: true
    add_column :kolide_issues, :value, :string, null: true
    add_column :kolide_issues, :data, :text, null: true
  end
end
