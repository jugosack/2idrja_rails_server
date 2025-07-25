class Instructor < ApplicationRecord
  has_one_attached :profile_pic

  # Validations (optional but recommended)
  validates :first_name, :last_name, :course_name, :description, :expertise, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
end
