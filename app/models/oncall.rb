class Oncall < ApplicationRecord
     belongs_to :user
     enum status: [:pending, :approved, :rejected]
     validates :start_date, presence: true
     validates :end_date, presence: true
     validates :reason, presence: true
end