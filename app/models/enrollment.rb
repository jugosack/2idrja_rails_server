class Enrollment < ApplicationRecord
  belongs_to :course
  belongs_to :user

  validates :user_id, uniqueness: { scope: :course_id, message: 'is already enrolled in this course' }
  after_create :update_course_places_left
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

  def course_not_full
    return unless course.places_left.present? && course.places_left <= 0

    errors.add(:course, 'is already full')
  end
end
