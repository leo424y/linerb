class AddStoreInfoToStore < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :place_id, :string
    add_column :stores, :price_level, :string
    add_column :stores, :rating, :string
    add_column :stores, :formatted_phone_number, :string
    add_column :stores, :opening_hours, :string
    add_column :stores, :website, :string
  end
end
