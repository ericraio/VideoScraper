class CreateEpisodes < ActiveRecord::Migration
  def change
    create_table :episodes do |t|
      t.string :title
      t.text :embed_url
      t.integer :anime_id

      t.timestamps
    end
  end
end
