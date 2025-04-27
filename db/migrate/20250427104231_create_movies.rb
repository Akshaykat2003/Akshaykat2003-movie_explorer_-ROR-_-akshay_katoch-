class CreateMovies < ActiveRecord::Migration[7.1]
  def change
    create_table :movies do |t|
      t.string :title
      t.string :genre
      t.integer :release_year
      t.float :rating
      t.string :director
      t.integer :duration
      t.text :description
      t.integer :plan

      t.timestamps
    end
  end
end
