# frozen_string_literal: true

class AlterKolideIdsToBigint < ActiveRecord::Migration[7.1]
  def up
    change_column :kolide_issues, :device_id, :bigint
    change_column :kolide_issues, :check_id, :bigint
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
