class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :confirmable,
         :validatable, :jwt_authenticatable, jwt_revocation_strategy: self

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :country, presence: true
  validates :mobile_number, presence: true
  validates :terms_of_use, acceptance: true

  # attr_accessor :unconfirmed_email
  
end
