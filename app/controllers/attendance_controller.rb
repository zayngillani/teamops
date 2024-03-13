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
                    SlackService.new(current_user, "Break Out", @break.break_in_time).send_message
                    redirect_to attendance_index_path
               else
               flash[:error] = "Break Already Marked"
               redirect_to attendance_index_path
               end
          else
               flash[:alert] = "Attendance Not Marked"
          end
     end

     
     

end
