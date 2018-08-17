class CreateIdeas < ActiveRecord::Migration[5.2]
  def change
    create_table :ideas do |t|
      t.string :user_id, index: true
      t.string :content

      t.timestamps
    end
  end
end
