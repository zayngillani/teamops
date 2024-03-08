class AttendanceController < ApplicationController

     def index
          @session = current_user.attendances.order(created_at: :desc)
          @user = User.find(current_user.id)
     end

     def create_session
            @session = Attendance.new
            @session.user_id = current_user.id
            @session.check_in_time = Time.now.utc
            @session.save!
            flash[:success] = "Checked IN successfully"
            SlackService.new(current_user, "Checked In", @session.check_in_time).send_message
            redirect_to root_path
     end

     def end_session
          @user = current_user
          @session = Attendance.where(user_id: @user.id).last
               @session.update!(check_out_time: Time.now.utc)
               duration_seconds = @session.check_out_time - @session.check_in_time
               @session.update!(total_hours: duration_seconds)
               flash[:success] = "Checked OUT successfully"
               SlackService.new(current_user, "Checked Out", @session.check_out_time).send_message
               redirect_to attendance_index_path
     end

     def break_session
          if @break = current_user.attendances.last
               if @break.present?  && @break.check_out_time.nil? && @break.break_out_time.nil? && @break.break_in_time.nil?
                    @break.update!(break_in_time: DateTime.now.strftime("%Y-%m-%d %H:%M:%S"))
               else @break.break_in_time.present? && @break.break_out_time.nil?
                    @break.update!(break_out_time: DateTime.now.strftime("%Y-%m-%d %H:%M:%S"))
               end
          else
               flash[:alert] = "Attendance Not Marked"
          end
     end

     
     

end
