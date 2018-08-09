class AddIndexToStore < ActiveRecord::Migration[5.1]
  def change
    add_index :stores, :info
    add_index :stores, :place_id
    add_index :stores, :group_id
    add_index :stores, :name_sys
    add_index :stores, :formatted_address
    add_index :stores, :lat
    add_index :stores, :lng
    add_index :stores, :place_types
  end
end
