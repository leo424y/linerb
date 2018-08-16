class CreateBooks < ActiveRecord::Migration[5.2]
  def change
    create_table :books do |t|
      t.string :user_id, index: true
      t.string :place_id, index: true
      t.decimal :cost

      t.timestamps
    end
  end
end
