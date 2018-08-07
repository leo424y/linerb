class ChangeTypeStore < ActiveRecord::Migration[5.1]
  def change
    change_column :stores, :lat, :decimal
    change_column :stores, :lng, :decimal
  end
end
