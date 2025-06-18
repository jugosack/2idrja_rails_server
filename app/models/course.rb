class Course < ApplicationRecord
  belongs_to :user
  has_one_attached :image, dependent: :purge_later
  # Validations
  validates :course_name, presence: true
  validates :fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_students, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :enrolled_students, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :places_left, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  enum course_status: { planned: 'planned', ongoing: 'ongoing', completed: 'completed', cancelled: 'cancelled' }, _prefix: true

  validates :course_status, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true

  validate :user_must_be_admin

  before_validation :calculate_places_left

  private

  def calculate_places_left
    return unless max_students.present? && enrolled_students.present?

    self.places_left = max_students - enrolled_students
    self.places_left = 0 if places_left.negative?
  end

  def user_must_be_admin
    return if user&.admin?

    errors.add(:user, 'must be an admin to create or manage courses')
  end
end
