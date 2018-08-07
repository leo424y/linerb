class ChangeTypeStore < ActiveRecord::Migration[5.1]
  def change
    change_column :stores, :lat, :decimal, using: 'lag::decimal'
    change_column :stores, :lng, :decimal, using: 'lng::decimal'
  end
end
