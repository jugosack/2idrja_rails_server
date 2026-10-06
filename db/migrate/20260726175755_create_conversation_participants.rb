class CreateConversationParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :conversation_participants,
              %i[conversation_id user_id],
              unique: true
  end
end
