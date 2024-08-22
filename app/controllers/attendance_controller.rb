class AttendanceController < ApplicationController
  before_action :restrict_ip, only: [:create_session, :end_session, :break_session]

     def index
      @user = current_user
     end

     def users_attendance
        @user = current_user
        @session = fetch_attendance_data
        calculate_total_hours if @session.present?
     end

     def create_session
      on_call_request = Oncall.where(request_status: 1, user_id: current_user.id).where("? BETWEEN start_date AND end_date", Date.today).first
      if on_call_request.present?
      else
        holiday = PublicHoliday.find_by(start_date: Date.today)
        if holiday.present?
          flash[:error] = "You can't check in on a #{holiday.title}."
          redirect_to attendance_index_path
          return
        end
    
        if Date.today.saturday? || Date.today.sunday?
          flash[:error] = "You can't check in on weekends."
          redirect_to attendance_index_path
          return
        end
    
        leave = current_user.leaves.where(start_date: Date.today.beginning_of_day..Date.today.end_of_day, status: "approved")
        if leave.present?
          flash[:error] = "You are on leave today, so you won't be able to check-in."
          redirect_to attendance_index_path
          return
        end
      end
    
      existing_session = current_user.attendances.where(check_in_time: Date.today.beginning_of_day..Date.today.end_of_day).first
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
      flash[:success] = "Checked in successfully"
      SlackService.new(current_user, "Checked In", @session.check_in_time).send_message
      redirect_to attendance_index_path
    end
    
   
     def end_session
      if params[:report].present?
        @session = current_user.attendances.last
        if @session.present?
          @session.update!(check_out_time: Time.now.utc)
          total_duration_seconds = @session.check_out_time - @session.check_in_time
          total_break_time = calculate_total_break_time(@session)
          total_duration_seconds -= total_break_time
          @session.update!(total_hours: total_duration_seconds)
          @session.update!(report: params[:report])
          channel = current_user.email.ends_with?("@techcreatix.com") ? ENV["REPORT_CHANNEL"] : ENV["TEST_CHANNEL"]
          SlackService.new(current_user, "Checked Out", @session.check_out_time, channel, params[:report]).send_report
          flash[:success] = "Report submitted and checkout successfully."
        else
          flash[:error] = "No active session found"
        end
        redirect_to attendance_index_path
      else
        flash[:error] = "Daily Report can't be empty"
        redirect_to root_path and return
      end
     end
    
   
     def break_session
      @session = current_user.attendances.last
          if @session && @session.check_out_time.nil?
            last_break = @session.breaks.last
            if last_break.nil? || (last_break.break_in_time.present? && last_break.break_out_time.present?)
              @session.breaks.create!(break_in_time: Time.now.utc)
              flash[:alert] = "On a break"
              SlackService.new(current_user, "Break In", Time.now.utc).send_message
            elsif last_break.break_in_time.present? && last_break.break_out_time.nil?
              last_break.update!(break_out_time: Time.now.utc)
              total_break_time = calculate_total_break_time(@session)
              @session.update!(total_break: total_break_time)
              flash[:alert] = "Back from break"
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
          redirect_to show_report_path
        end

        def show_report
          @user = current_user
          @session = fetch_attendance_data
        end

        def user_report
          @daily_report = Attendance.find_by(id: params[:format])
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

    def restrict_ip
      if current_user&.can_outside_access == false
        allowed_ips = IpManagement.where(deleted_at: nil, status: 0).pluck(:ip_address)
        client_ip = request.headers['X-Forwarded-For'] || request.remote_ip
        Rails.logger.info "Client IP: #{client_ip}"
        Rails.logger.info "Allowed IPs: #{allowed_ips.inspect}"
        unless allowed_ips.include?(client_ip)
          redirect_to root_path, alert: 'Access denied from this IP address.'
        end
      else
        return
      end
    end

     def fetch_attendance_data
      @month = params[:month].present? ? params[:month].to_i : Date.today.month
      @year = params[:year].present? ? params[:year].to_i : Date.today.year
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @attendance_records = Attendance.where(
        "check_in_time <= ? AND (check_out_time >= ? OR check_out_time IS NULL) AND user_id = ?",
        @end_date.end_of_day, @start_date.beginning_of_day, current_user.id
      ).order(created_at: :desc)
      @today_attendance = @attendance_records.find do |record|
        record.check_in_time.to_date == Date.today
      end
      @attendance_records
     end
  
     def calculate_total_hours
      total_hrs = 0
      @session.each do |attendance|
        total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
      end
      @total_hours = total_hrs
     end
end