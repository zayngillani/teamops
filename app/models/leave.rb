class Leave < ApplicationRecord
  belongs_to :user
  validates :reason, presence: true
  enum status: [:pending, :approved, :rejected]
  enum leave_type: {quarterly: 0 , annual: 1, wedding: 2}

  def pending?
    status == 0
  end
end
