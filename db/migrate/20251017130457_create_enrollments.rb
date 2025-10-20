class CreateEnrollments < ActiveRecord::Migration[7.0]
  def change
    create_table :enrollments do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    # Add uniqueness to prevent double enrollment
    add_index :enrollments, %i[course_id user_id], unique: true
  end
end
