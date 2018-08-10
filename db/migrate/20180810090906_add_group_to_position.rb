class AddGroupToPosition < ActiveRecord::Migration[5.1]
  def change
    add_column :positions, :group_id, :string
  end
end
