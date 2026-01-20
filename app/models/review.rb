class Review < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :rating, inclusion: { in: 1..5 }
  validates :body, presence: true
end
