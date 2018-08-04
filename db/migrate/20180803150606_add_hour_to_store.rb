class AddAddressToStore < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :weekday_text, :string
  end
end
