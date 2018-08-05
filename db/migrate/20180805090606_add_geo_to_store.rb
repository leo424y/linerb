class AddGeoToStore < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :address_components, :string
    add_column :stores, :lat, :string
    add_column :stores, :lng, :string
  end
end
