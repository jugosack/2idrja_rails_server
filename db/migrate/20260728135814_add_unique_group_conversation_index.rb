class AddUniqueGroupConversationIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :conversations,
              %i[course_id conversation_type],
              unique: true,
              where: "conversation_type = 'group'",
              name: 'index_unique_group_conversations'
  end
end
