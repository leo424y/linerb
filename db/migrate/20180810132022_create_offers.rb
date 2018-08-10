class CreateOffers < ActiveRecord::Migration[5.2]
  def change
    create_table :offers do |t|
      t.string :user_id, index: true
      t.string :group_id, index: true
      t.string :store_name
      t.string :info
      t.string :likes

      t.timestamps
    end
  end
end
