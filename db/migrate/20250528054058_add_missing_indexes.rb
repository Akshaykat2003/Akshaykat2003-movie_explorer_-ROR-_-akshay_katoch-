class AddMissingIndexes < ActiveRecord::Migration[7.1]
 def change
    add_index :movies, :title unless index_exists?(:movies, :title)
    add_index :movies, :genre unless index_exists?(:movies, :genre)
    add_index :movies, :release_year unless index_exists?(:movies, :release_year)
    add_index :movies, :rating unless index_exists?(:movies, :rating)

    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :notifications_enabled unless index_exists?(:users, :notifications_enabled)
  end
end
