class ConversationParticipant < ApplicationRecord
  belongs_to :conversation, inverse_of: :conversation_participants
  belongs_to :user, inverse_of: :conversation_participants

  validates :user_id,
            uniqueness: { scope: :conversation_id }
end
