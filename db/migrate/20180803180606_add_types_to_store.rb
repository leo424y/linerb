class AddHourToStore < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :place_types, :string
  end
end
