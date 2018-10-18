class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      t.string :user_id
      t.string :group_id
      t.string :place_name
      t.string :info

      t.timestamps
    end
  end
end
