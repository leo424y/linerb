class AddInfoToGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :groups, :display_name, :string
    add_column :groups, :points, :integer, default: 0
  end
end
