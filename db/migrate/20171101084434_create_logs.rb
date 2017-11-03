class CreateLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :logs do |t|
      t.string :area
      t.string :info

      t.timestamps
    end
  end
end
