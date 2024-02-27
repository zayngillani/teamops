class AttendanceController < ApplicationController

     def create_session
          existing_session = Attendance.find_by(user_id: current_user.id, check_in_time: Date.today.beginning_of_day..Date.today.end_of_day)
          if existing_session.present?
            flash[:notice] = "You have already checked in for today."
          else
            @session = Attendance.new
            @session.user_id = current_user.id
            @session.check_in_time = DateTime.now.strftime("%Y-%m-%d %H:%M:%S")
            @session.save!
          end
     end

     def end_session
          @user = current_user
          session = Attendance.where(user_id: @user.id).last
          if session.present? && session.check_in_time.present? && session.check_out_time.nil?
               session.update!(check_out_time: DateTime.now.strftime("%Y-%m-%d %H:%M:%S"))
               duration_seconds = session.check_out_time - session.check_in_time
               session.update!(total_hours: duration_seconds)
          else
               flash[:notice] = "Attendance Not Marked"

          end
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

     def generate_pdf
          @user = User.find(params[:id])
          @user_sessions = Attendance.where(user_id: params[:id])
          respond_to do |format|
               format.html
               format.pdf { render pdf: "#{@user.name}", layout: false } # Specify view and disable layout
          end
     end

end
