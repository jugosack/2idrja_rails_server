class Enrollment < ApplicationRecord
  belongs_to :course
  belongs_to :user

  # rubocop:disable-next Rails/I18nLocaleTexts
  validates :user_id, uniqueness: { scope: :course_id, message: 'is already enrolled in this course' }
  after_create :update_course_places_left
  after_create :join_group_chat
  after_destroy :leave_group_chat
  after_commit :send_enrollment_email, on: :create

  validate :course_not_full

  private

  def update_course_places_left
    course.calculate_places_left
    course.save!
  end

  def send_enrollment_email
    EnrollmentMailer.enrollment_confirmation(self).deliver_later
    EnrollmentMailer.admin_notification(self).deliver_later
  end

  def join_group_chat
    conversation = course.conversations.find_by(conversation_type: 'group')
    return unless conversation

    conversation.conversation_participants.find_or_create_by!(
      user: user
    )
  end

  def leave_group_chat
    conversation = course.conversations.find_by(conversation_type: 'group')
    return unless conversation

    conversation.conversation_participants
                .where(user: user)
                .destroy_all
  end

  def course_not_full
    return unless course.places_left.present? && course.places_left <= 0

    errors.add(:course, 'is already full')
  end
end
