class CreateVips < ActiveRecord::Migration[5.2]
  def change
    create_table :vips do |t|
      t.string :user_id
      t.string :group_id

      t.timestamps
    end
  end
end
