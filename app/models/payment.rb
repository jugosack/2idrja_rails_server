class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :stripe_payment_intent_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending succeeded failed] }

  enum status: {
    pending: 'pending',
    succeeded: 'succeeded',
    failed: 'failed'
  }, _prefix: true
end
