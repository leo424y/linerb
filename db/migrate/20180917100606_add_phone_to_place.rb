class AddPlaceInfoToPlace < ActiveRecord::Migration[5.1]
  def change
    add_column :places, :formatted_phone_number, :string
  end
end
