class AddAddressToStore < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :formatted_address, :string
    add_column :stores, :name_sys, :string
  end
end
