class Leave < ApplicationRecord
  belongs_to :user
  validates :reason, presence: true
  enum status: [:pending, :approved, :rejected]
  enum leave_type: {quarterly: 0 , annual: 1, wedding: 2}
  scope :for_month, ->(user_id, month, year) {
    where(user_id: user_id)
    .where('EXTRACT(MONTH FROM start_date) = ? AND EXTRACT(YEAR FROM start_date) = ?', month, year)}
end
