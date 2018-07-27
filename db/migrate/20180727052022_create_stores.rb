class CreateStores < ActiveRecord::Migration[5.2]
  def change
    create_table :stores do |t|
      t.string :name
      t.string :info
      t.intger :view

      t.timestamps
    end
  end
end
