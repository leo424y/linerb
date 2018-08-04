class AddPeriodsToStore < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :periods, :string
  end
end
