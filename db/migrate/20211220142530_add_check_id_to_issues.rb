# frozen_string_literal: true

class AddCheckIdToIssues < ActiveRecord::Migration[6.1]
  def up
    add_column :kolide_issues, :check_id, :integer
  end

  def down
    remove_column :kolide_issues, :check_id
  end
end
