class CreateReviews < ActiveRecord::Migration[5.2]
  def change
    create_table :reviews do |t|
      t.string :place_id, index: true
      t.string :author_name
      t.string :author_url
      t.string :profile_photo_url
      t.string :rating
      t.string :text

      t.timestamps
    end
  end
end
