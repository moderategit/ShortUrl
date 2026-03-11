class CreateShortUrls < ActiveRecord::Migration[7.0]
  def change
    create_table :short_urls do |t|
      t.string :path, null: false
      t.string :target_url, null: false
      t.string :title

      t.timestamps
    end

    add_index :short_urls, :path, unique: true
  end
end
