class CreateTalks < ActiveRecord::Migration[5.2]
  def change
    create_table :talks do |t|
      t.string :user_id
      t.string :group_id
      t.string :talk

      t.timestamps
    end
  end
end
