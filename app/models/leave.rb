class Leave < ApplicationRecord
  belongs_to :user
  enum status: [:pending, :approved, :rejected]
  enum leave_type: {quaterly: 0 , annual: 1}
end
