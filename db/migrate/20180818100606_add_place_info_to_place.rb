class AddPlaceInfoToPlace < ActiveRecord::Migration[5.1]
  def change
    add_column :places, :place_id, :string, index: true
    add_column :places, :place_name, :string
    add_column :places, :place_name_glink, :string
    add_column :places, :formatted_address, :string
    add_column :places, :weekday_text, :string
    add_column :places, :place_types, :string
    add_column :places, :periods, :string
    add_column :places, :address_components, :string
    add_column :places, :lat, :string, index: true
    add_column :places, :lng, :string, index: true
  end
end
