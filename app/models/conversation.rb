class Conversation < ApplicationRecord
  belongs_to :course

  has_many :conversation_participants,
           dependent: :destroy,
           inverse_of: :conversation

  has_many :participants,
           through: :conversation_participants,
           source: :user

  # rubocop:disable Rails/InverseOf
  has_many :messages,
           # rubocop:enable Rails/InverseOf
           -> { order(created_at: :asc) },
           dependent: :destroy

  # rubocop:disable Rails/HasManyOrHasOneDependent, Rails/InverseOf
  has_one :last_message,
          # rubocop:enable Rails/HasManyOrHasOneDependent, Rails/InverseOf
          -> { order(created_at: :desc) },
          class_name: 'Message'

  # enum :conversation_type,
  #      {
  #        group: "group",
  #        private: "private"
  #      },
  #      prefix: true

  enum :conversation_type,
       {
         group: 'group',
         private: 'private'
       },
       prefix: :conversation

  validates :conversation_type, presence: true

  validates :course_id,
            uniqueness: {
              scope: :conversation_type,
              conditions: -> { where(conversation_type: 'group') }
            }

  def participant?(user)
    participants.exists?(id: user.id)
  end

  def self.find_or_create_private(course, user1, user2)
    unless course.users.exists?(id: user1.id) || course.user_id == user1.id
      raise ActiveRecord::RecordInvalid,
            "User #{user1.id} is not a course participant"
    end

    unless course.users.exists?(id: user2.id) || course.user_id == user2.id
      raise ActiveRecord::RecordInvalid,
            "User #{user2.id} is not a course participant"
    end

    conversation = Conversation
                   .conversation_private
                   .where(course: course)
                   .includes(:participants)
                   .detect do |c|
                     c.participant_ids.sort == [user1.id, user2.id].sort
                   end

    return conversation if conversation

    Conversation.transaction do
      conversation = Conversation.create!(
        course: course,
        conversation_type: :private
      )

      conversation.participants << [user1, user2]

      conversation
    end
  end
end
