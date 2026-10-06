class CreateConversations < ActiveRecord::Migration[7.0]
  def change
    create_table :conversations do |t|
      t.references :course, null: false, foreign_key: true
      t.string :conversation_type, null: false # "group" or "private"

      t.timestamps
    end
  end
end
