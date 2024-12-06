class Attendance < ApplicationRecord
     belongs_to :user
     has_many :breaks, dependent: :destroy

     def self.find_today_checkin(user)
       where(user: user)
          .where("DATE(check_in_time) = ?", Date.current)
          .first
     end

     def calculate_total_break_time
          total_break_time_seconds = 0
          self.breaks.each do |break_instance|
            if break_instance.break_in_time.present? && break_instance.break_out_time.present?
              break_duration_seconds = break_instance.break_out_time - break_instance.break_in_time
              total_break_time_seconds += break_duration_seconds
            end
          end
      
          total_break_time_seconds
        end
end
