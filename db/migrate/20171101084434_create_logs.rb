class CreateLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :logs do |t|
      t.string :area
      t.integer :count

      t.timestamps
    end
  end
end
