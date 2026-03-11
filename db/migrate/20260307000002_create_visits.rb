class CreateVisits < ActiveRecord::Migration[7.0]
  def change
    create_table :visits do |t|
      t.references :short_url, null: false, foreign_key: true
      t.string :ip_address
      t.float :latitude
      t.float :longitude
      t.string :country
      t.datetime :visited_at, null: false

      t.timestamps
    end

    # Only index visited_at manually; short_url_id is already indexed
    add_index :visits, :visited_at
  end
end