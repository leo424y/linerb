class AddCountToGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :groups, :talk_count, :integer, default: 0
    add_column :groups, :use_count, :integer, default: 0
    add_column :groups, :result_count, :integer, default: 0
  end
end
