class CreatePostions < ActiveRecord::Migration[5.2]
  def change
    create_table :positions do |t|
      t.string :user_id
      t.decimal :lat
      t.decimal :lng

      t.timestamps
    end
  end
end
