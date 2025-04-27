class AddDefaultToPlanInMovies < ActiveRecord::Migration[7.1]
  def change
    change_column_default :movies, :plan, 0
  end
end
