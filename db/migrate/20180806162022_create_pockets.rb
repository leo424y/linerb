class CreatePockets < ActiveRecord::Migration[5.2]
  def change
    create_table :pockets do |t|
      t.string :user_id
      t.string :place_name

      t.timestamps
    end
  end
end
