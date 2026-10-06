class AddCourseConversationTypeIndexToConversations < ActiveRecord::Migration[7.0]
  def change
    add_index :conversations, %i[course_id conversation_type]
  end
end
