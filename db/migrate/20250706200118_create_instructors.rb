class CreateInstructors < ActiveRecord::Migration[7.0]
  def change
    create_table :instructors do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :course_name, null: false
      t.text :description, null: false
      t.string :expertise, null: false
      t.string :email, null: false

      t.timestamps
    end
  end
end
