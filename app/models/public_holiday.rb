class PublicHoliday < ApplicationRecord
     scope :on_date, ->(date) { where('start_date <= ? AND end_date >= ?', date, date) }
     def self.holiday_on?(date)
          where('start_date <= ? AND end_date >= ?', date, date).exists?
     end
end
