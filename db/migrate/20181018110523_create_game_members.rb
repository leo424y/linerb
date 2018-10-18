class CreateGameMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :game_members do |t|
      t.integer :game_id
      t.string :user_id

      t.timestamps
    end
  end
end
