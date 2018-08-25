class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :user_id, index: true
      t.string :display_name
      t.string :picture_url
      t.string :status_message
      t.integer :points, default: 0

      t.timestamps
    end
  end
end
