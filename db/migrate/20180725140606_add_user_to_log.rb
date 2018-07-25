class AddUserToLog < ActiveRecord::Migration[5.1]
  def change
    add_column :logs, :ticket_user
    add_column :logs, :ticket_status
    add_column :logs, :ticket_count, :integer
  end
end
