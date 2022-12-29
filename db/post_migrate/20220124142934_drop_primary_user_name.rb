# frozen_string_literal: true

class DropPrimaryUserName < ActiveRecord::Migration[6.1]
  DROPPED_COLUMNS ||= { kolide_devices: %i[primary_user_name] }

  def up
    DROPPED_COLUMNS.each { |table, columns| Migration::ColumnDropper.execute_drop(table, columns) }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
