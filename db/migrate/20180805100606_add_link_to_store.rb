class AddLinkToStore < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :s_link, :string
  end
end
