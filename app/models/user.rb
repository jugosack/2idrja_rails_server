class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :confirmable,
         :validatable, :jwt_authenticatable, jwt_revocation_strategy: self

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :country, presence: true
  validates :mobile_number, presence: true
  validates :terms_of_use, acceptance: true

  has_many :conversations, through: :conversation_participants
  has_many :conversation_participants,
           dependent: :destroy,
           inverse_of: :user

  has_many :messages, dependent: :destroy
  # attr_accessor :unconfirmed_email
  has_one_attached :avatar
  # rubocop:disable-next Rails/HasManyOrHasOneDependent
  has_many :courses
  has_many :reviews, dependent: :destroy

  has_many :enrollments, dependent: :destroy
  has_many :enrolled_courses, through: :enrollments, source: :course

  enum :role, { user: 'user', admin: 'admin' }

  before_validation :set_default_role, on: :create

  private

  def set_default_role
    self.role ||= 'user'
  end
end
