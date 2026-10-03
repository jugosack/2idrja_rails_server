class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user

  has_many_attached :files, dependent: :purge_later

  validates :body,
            length: { maximum: 5000 },
            allow_blank: true

  validate :body_or_files_present
  validate :user_is_participant

  private

  def body_or_files_present
    return if body.to_s.strip.present? || files.attached?

    errors.add(:base, 'Message cannot be empty')
  end

  def user_is_participant
    return if conversation.participant?(user)

    errors.add(:user, 'is not a participant')
  end
end
