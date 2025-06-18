class RemoveImageFromCourses < ActiveRecord::Migration[7.0]
  def change
    remove_column :courses, :image, :string
  end
end
