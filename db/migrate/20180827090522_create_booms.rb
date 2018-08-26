class CreateBooms < ActiveRecord::Migration[5.2]
  def change
    create_table :booms do |t|
      t.string :user_id, index: true
      t.string :boom_user_id, index: true

      t.timestamps
    end
  end
end
