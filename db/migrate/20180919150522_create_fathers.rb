class CreateFathers < ActiveRecord::Migration[5.2]
  def change
    create_table :fathers do |t|
      t.string :group
      t.string :name, index: true
      t.string :photo
      t.string :phone
      t.string :address

      t.timestamps
    end
  end
end
