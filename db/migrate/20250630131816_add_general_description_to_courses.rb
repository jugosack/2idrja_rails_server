class AddGeneralDescriptionToCourses < ActiveRecord::Migration[7.0]
  def change
   add_column :courses, :general_description, :text, null: false, default: "To be added"
  end
end
