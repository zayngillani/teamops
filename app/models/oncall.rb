class Oncall < ApplicationRecord
     belongs_to :user
     enum status: [:pending, :approved, :rejected]
     validates :start_date, presence: true
     validates :end_date, presence: true
     validates :reason, presence: true
     scope :for_month, ->(user_id, month, year) {
          start_of_month = Date.new(year, month, 1)
          end_of_month = start_of_month.end_of_month
          where(user_id: user_id)
            .where('start_date <= ? AND end_date >= ?', end_of_month, start_of_month)
        }        
end