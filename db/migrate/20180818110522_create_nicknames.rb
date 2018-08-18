class CreateNicknames < ActiveRecord::Migration[5.2]
  def change
    create_table :nicknames do |t|
      t.string :place_id, index: true
      t.string :nickname, index: true
      t.string :place_name, index: true

      t.timestamps
    end
  end
end
