class CreateGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :groups do |t|
      t.string :user_id
      t.string :group_id
      t.string :status

      t.timestamps
    end
  end
end
