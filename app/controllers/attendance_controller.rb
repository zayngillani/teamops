class AttendanceController < ApplicationController

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
       holiday = PublicHoliday.find_by(start_date: Date.today)
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
       pending_session = current_user.attendances.last
       if pending_session.present? && pending_session.check_out_time.nil?
         checkout_time = pending_session.check_in_time + 8.hours
         pending_session.update(check_out_time: checkout_time)
         total_duration_seconds = checkout_time - pending_session.check_in_time
         total_break_time = pending_session.breaks.sum { |br| br.break_out_time - br.break_in_time if br.break_in_time.present? && br.break_out_time.present? }
         total_duration_seconds -= total_break_time
         pending_session.update!(total_hours: total_duration_seconds)
       end
   
       @session = current_user.attendances.create!(check_in_time: Time.now.utc)
       flash[:success] = "Checked IN successfully"
      #  SlackService.new(current_user, "Checked In", @session.check_in_time).send_message
       redirect_to attendance_index_path
     end
   
     def end_session
       @session = current_user.attendances.last
       if @session
        if params[:report].present?
          @session.update!(report: params[:report])
        end
        @session.update!(check_out_time: Time.now.utc)
        total_duration_seconds = @session.check_out_time - @session.check_in_time
         total_break_time = calculate_total_break_time(@session)
         total_duration_seconds -= total_break_time
         @session.update!(total_hours: total_duration_seconds)
         flash[:success] = "Checked OUT successfully"
         #  SlackService.new(current_user, "Checked Out", @session.check_out_time).send_message
       else
         flash[:error] = "No active session found"
        end
       redirect_to attendance_index_path
     end
   
     def break_session
      @session = current_user.attendances.last
          if @session && @session.check_out_time.nil?
            last_break = @session.breaks.last
            if last_break.nil? || (last_break.break_in_time.present? && last_break.break_out_time.present?)
              @session.breaks.create!(break_in_time: Time.now.utc)
              flash[:success] = "Break IN successfully"
              SlackService.new(current_user, "Break In", Time.now.utc).send_message
            elsif last_break.break_in_time.present? && last_break.break_out_time.nil?
              last_break.update!(break_out_time: Time.now.utc)
              total_break_time = calculate_total_break_time(@session)
              @session.update!(total_break: total_break_time)
              flash[:success] = "Break Out successfully"
              SlackService.new(current_user, "Break Out", Time.now.utc).send_message
            else
              flash[:error] = "Unable to mark break"
            end
          else
            flash[:error] = "No active session or session already checked out"
          end
          redirect_to attendance_index_path
        end
        
        def update_report
          @attendance = Attendance.find_by(id: params[:id])
          if @attendance.present?
            @attendance.update!(report: params[:report])
            flash[:success] = "Daily Report updated successfully"
          else
            flash[:error] = "Attendance Not Present"
          end
          redirect_to attendance_index_path
        end
     private
     
     def calculate_total_break_time(session)
          total_break_time_seconds = 0
          session.breaks.each do |break_instance|
               if break_instance.break_in_time.present? && break_instance.break_out_time.present?
               break_duration_seconds = break_instance.break_out_time - break_instance.break_in_time
               total_break_time_seconds += break_duration_seconds
               end
          end
          total_break_time_seconds
     end
end