class CreateAlias < ActiveRecord::Migration[5.2]
  def change
    create_table :alias do |t|
      t.string :place_id, index: true
      t.string :alias_name, index: true
      t.string :place_name

      t.timestamps
    end
  end
end
