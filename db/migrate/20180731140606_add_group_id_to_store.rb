class AddGroupIdToStore < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :group_id, :string
  end
end
