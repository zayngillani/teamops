class AttendanceController < ApplicationController
     before_action :detect_device_type, only: [:create_session, :end_session]

     def index
          first_day_of_month = Date.current.beginning_of_month
          last_day_of_month = Date.current.end_of_month
          @session = current_user.attendances.where(created_at: first_day_of_month.beginning_of_day..last_day_of_month.end_of_day).order(created_at: :desc)
          @user = current_user
          if @session.present?
            total_hrs = 0
            @session.each do |attendance|
              total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
            end
            @total_hours = total_hrs
          end
     end

     def create_session
          holiday = Holiday.find_by(start_date: Date.today)
          if holiday.present?
               flash[:error] = "You can't check in on a #{holiday.title}."
               redirect_to attendance_index_path
               return
          end
          existing_session = current_user.attendances.where(check_in_time: Date.today.beginning_of_day..Date.today.end_of_day).first
          leave = current_user.leaves.where(start_date: Date.today.beginning_of_day..Date.today.end_of_day, status: "approved")
          if leave.present?
               flash[:error] = "You are on leave today, so you won't be able to check-in."
               redirect_to attendance_index_path
               return
          end
          if existing_session
            flash[:error] = "You have already checked in today"
            redirect_to attendance_index_path
            return
          end
          @session = Attendance.new
          @session.user_id = current_user.id
          @session.check_in_time = Time.now.utc
          @session.save!
          flash[:success] = "Checked IN successfully"
          SlackService.new(current_user, "Checked In", @session.check_in_time).send_message
          redirect_to attendance_index_path
        end

     def end_session
          @user = current_user
          @session = Attendance.where(user_id: @user.id).last
               @session.update!(check_out_time: Time.now.utc)
               total_duration_seconds = @session.check_out_time - @session.check_in_time
               if @session.break_in_time.present? && @session.break_out_time.present?
               total_break = @session.break_out_time - @session.break_in_time
               total_duration_seconds -= total_break
               end
               @session.update!(total_hours: total_duration_seconds)
               flash[:success] = "Checked OUT successfully"
               SlackService.new(current_user, "Checked Out", @session.check_out_time).send_message
               redirect_to attendance_index_path
     end

     def break_session
          if @break = current_user.attendances.last
               if @break.present?  && @break.check_out_time.nil? && @break.break_out_time.nil? && @break.break_in_time.nil?
                    @break.update!(break_in_time: Time.now.utc)
                    flash[:success] = "Break In successfully"
                    SlackService.new(current_user, "Break In", @break.break_in_time).send_message
                    redirect_to attendance_index_path
               elsif @break.break_in_time.present? && @break.break_out_time.nil?
                    @break.update!(break_out_time: Time.now.utc)
                    flash[:success] = "Break OUT successfully"
                    SlackService.new(current_user, "Break Out", @break.break_out_time).send_message
                    redirect_to attendance_index_path
               else
               flash[:error] = "Break Already Marked"
               redirect_to attendance_index_path
               end
          else
               flash[:alert] = "Attendance Not Marked"
          end
     end

     private

     def detect_device_type
       request.variant = :mobile if mobile_device?
       redirect_to root_path, alert: "Check-in and check-out are not allowed from mobile devices."
     end
      
     def mobile_device?
       detector = DeviceDetector.new(request.user_agent)
       detector.device_type == 'smartphone' || detector.device_type == 'tablet'
     end
end
