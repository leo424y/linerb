class CreateIssues < ActiveRecord::Migration[5.2]
  def change
    create_table :issues do |t|
      t.string :user_id
      t.string :group_id
      t.string :title
      t.string :tag
      t.string :status
      t.integer :like, default: 0
      t.string :ref

      t.timestamps
    end
  end
end
