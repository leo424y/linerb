class CreatePoints < ActiveRecord::Migration[5.2]
  def change
    create_table :points do |t|
      t.string :user_id, index: true
      t.string :group_id, index: true
      t.integer :points, default: 0

      t.timestamps
    end
  end
end
