class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.string :course_name, null: false
      t.date :start_date
      t.date :end_date
      t.string :image
      t.text :description
      t.text :benefits
      t.text :target_audience
      t.text :additional_info
      t.decimal :fee, precision: 10, scale: 2
      t.integer :max_students
      t.integer :enrolled_students, default: 0
      t.integer :places_left
      t.string :course_status
      t.float :rating

      t.timestamps
    end
  end
end
