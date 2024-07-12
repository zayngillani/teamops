class Admin::UsersController < ApplicationController

     def index
      session = User.where(role: "user", deleted: false).order(created_at: :desc)
      @session = session.paginate(page: params[:page], per_page: 10)
     end

     def new
       @user = User.new
     end
   
    def create
      unless params[:user][:password] == params[:user][:password_confirmation]
        flash[:error] = "Passwords don't match. Please check and re-type your confirm password."
        redirect_to new_admin_user_path and return
      end
      if params[:user][:email] =~ /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/
        @existing_user = User.find_by(email: params[:user][:email])
        if @existing_user.present?
          flash[:error] = "Email Already Exists"
          redirect_to root_path
        else
          @user = User.new(user_params)
          @user.ip_address = "#{request.headers['X-Forwarded-For']&.split(',')&.last&.strip || request.ip || request.remote_ip}"
          @user.role = "user"
          @user.password = params[:user][:password]
          @user.password_confirmation = params[:user][:password_confirmation]
          if @user.save
            flash[:success] = "User created successfully"
            redirect_to root_path
          else
            render 'new'
          end
        end
      else
        flash[:error] = "Invalid Email Format"
        redirect_to root_path
      end
    end

    def edit
      @user = User.find_by(id: params[:id]) if params[:id].present?
    end
    
    def update
      @user = User.find_by(id: params[:id])
      if @user.present?
        @user.update(user_params)
          if params[:user][:password].present? && params[:user][:password] == params[:user][:password_confirmation]
            @user.update!(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
          end
        flash[:success] = "User updated successfully"
        redirect_to root_path
      else
        flash[:error] = "User not found"
      end
    end

    def user_profile
      @user = User.find_by(id: params[:format]) if params[:format].present?
      name = @user.name
      @first_name = name.split.first[0]
      @last_name = name.split.last[0]
    end

    def generate_pdf
      @user = User.find(params[:id])
      @month = params[:month].to_i
      @year = params[:year].to_i
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", @start_date.end_of_month, @end_date.beginning_of_month)
      date_range = (@start_date..@end_date).reject { |date| date.saturday? || date.sunday? }
      if @public_holidays.present?
        @public_holidays.each do |holiday|
          date_range.reject! { |date| date.between?(holiday.start_date, holiday.end_date) }
        end
      end
      @user_sessions = @user.attendances.where(check_in_time: @start_date.beginning_of_day..@end_date.end_of_day).order(created_at: :asc)
      present_dates = @user_sessions.pluck(:check_in_time).map(&:to_date)
      created_date = @user.created_at.to_date
      @leaves = date_range.count { |date|
        !present_dates.include?(date) && date >= created_date && date <= Date.today
      }
      if @user_sessions.present?
        total_hrs = @user_sessions.sum(:total_hours)
        @total_hours = total_hrs
        respond_to do |format|
          format.html
          format.pdf { render pdf: @user.name, layout: false }
        end
      else
        flash[:error] = "Attendance Not Present"
        redirect_to admin_report_path and return
      end
    end
    

    def destroy
      @user = User.find_by(id: params[:id])
      if @user
        @user.update(deleted: true)
        flash[:success] = "User deleted successfully"
        redirect_to root_path
      else
        flash[:error] = "User Already Deleted"
        redirect_to root_path
      end
    end

    def disable_user
      @user = User.find_by(id: params[:id])
      if @user.present?
        if @user.status == "active"
          @user.update(status: 1)
          disable_attendance(@user)
          flash[:success] = "User disabled successfully"
          redirect_to admin_users_path
        elsif @user.status == "pending"
          @user.update(status: 0)
          flash[:success] = "User undisabled successfully"
          redirect_to admin_users_path
        else
          flash[:error] = "User Already Disabled"
          redirect_to admin_users_path
        end
      else
        flash[:error] = "User Not Found"
        redirect_to admin_users_path
      end
    end

    def report
      session = User.active.where(role: "user", deleted: false).order(created_at: :desc)
      @session = session.paginate(page: params[:page], per_page: 10)
    end

    def user_detail
      @user = User.find_by(id: params[:id])
      @month = params[:month].to_i
      @year = params[:year].to_i
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @user_sessions = @user.attendances.where(check_in_time: @start_date.beginning_of_day..@end_date.end_of_day).order(created_at: :asc)
      @all_sessions = @user.attendances
      date_range = (@start_date.to_date..@end_date.to_date).to_a
      date_range.reject! { |date| date.saturday? || date.sunday? }
      present_dates = @user_sessions.pluck(:check_in_time).map(&:to_date)
      created_date = @user.created_at.to_date

      if @user_sessions.present?
        total_hrs = 0
        @user_sessions.each do |attendance|
          total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
        end
        @total_hours = total_hrs
      elsif @all_sessions.present?
        @sessions
      elsif
        flash[:error] = "Attendance Not Present"
        redirect_to root_path
      end
    end

    def user_leave
      @user = User.find_by(id: params[:id])
      @month = params[:month].to_i
      @year = params[:year].to_i
      @users = User.active.where(role: "user", deleted: false).order(created_at: :desc)
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
    end

    def leave_report
      @month = params[:month].to_i
      @year = params[:year].to_i
      @users = User.active.where(role: "user", deleted: false).order(created_at: :desc)
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", @start_date.end_of_month, @end_date.beginning_of_month)
      @user_leaves = {}
      @users.each do |user|
        date_range = (@start_date..@end_date).reject { |date| date.saturday? || date.sunday? }
        if @public_holidays.present?
          @public_holidays.each do |holiday|
            date_range.reject! { |date| date.between?(holiday.start_date, holiday.end_date) }
          end
        end
        present_dates = user.attendances.pluck(:check_in_time).map(&:to_date)
        created_date = user.created_at.to_date
        leaves = date_range.count { |date|
          !present_dates.include?(date) && date >= created_date && date <= Date.today
        }
        @user_leaves[user.name] = leaves
      end
      if @user_leaves.present?
        respond_to do |format|
          format.html
          format.pdf { render pdf: "LeaveReport_#{Date::MONTHNAMES[@month]}#{@year}", layout: false } # Specify view and disable layout
        end
      else
        flash[:error] = "Attendance Not Present"
        redirect_to root_path
      end
    end

    def monthly_excel
      if params[:selected_users].present?
        user_ids = params[:selected_users].split(',')
        @users = User.where(id: user_ids)
      else
        @users = User.active.where(role: "user", deleted: false).order(created_at: :desc)
      end
      @month = params[:month].to_i
      @year = params[:year].to_i
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @total_hours = {}
      @leaves = {}
      current_month_start = @start_date.beginning_of_month
      current_month_end = @end_date.end_of_month
      @public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", current_month_end, current_month_start)
      @users.each do |user|
        @user_sessions = user.attendances.where(check_in_time: @start_date.beginning_of_day..@end_date.end_of_day).order(created_at: :asc)
        total_hrs = 0
        @user_sessions.each do |attendance|
          total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
        end
        @total_hours[user.id] = total_hrs
        regular_hours_per_day = 8
        date_range = (@start_date..@end_date).to_a
        working_days = calculate_working_days(@start_date, @end_date)
        @public_holidays.each do |holiday|
          working_days -= (holiday.start_date..holiday.end_date).count
        end
        @total_working_hours = working_days * regular_hours_per_day
      end
      respond_to do |format|
        format.xlsx do
          xlsx_package = Axlsx::Package.new
          xlsx_package.use_shared_strings = true
          wb = xlsx_package.workbook
          columns_to_include = params[:selected_columns].split(',') || []
          wb.add_worksheet(name: "Monthly Report") do |sheet|
            headers = []
            headers += columns_to_include.map(&:humanize)
            sheet.add_row headers
            @users.each do |user|
              current_user_leaves = Leave.where("start_date <= ? AND end_date >= ? AND status = ? AND user_id = ?", @end_date, @start_date, 1, user.id).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }
              reg_hours = user.leaves.present? ? (@total_working_hours - current_user_leaves * 8) : @total_working_hours
              @regular_hours = reg_hours
              working_hours = @total_hours[user.id] / 3600
              overtime = @regular_hours < working_hours ? (working_hours - @regular_hours) : 0
              undertime = @regular_hours > working_hours ? (@regular_hours - working_hours) : 0
              data_row = [user.name]
              columns_to_include.each do |column|
                case column
                when 'regular_hours'
                  data_row << reg_hours
                when 'working_hours'
                  data_row << working_hours
                when 'overtime'
                  data_row << overtime
                when 'undertime'
                  data_row << undertime
                when 'leaves'
                  data_row << current_user_leaves
                end
              end
              sheet.add_row data_row
            end
          end
          @users.each do |user|
            current_user_leaves = Leave.where("start_date <= ? AND end_date >= ? AND status = ? AND user_id = ?", @end_date, @start_date, 1, user.id).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }
            wb.add_worksheet(name: "#{user.name}_#{user.id}") do |sheet|
              sheet.add_row ["Date", "Check In", "Check Out", "Regular Hours", "Overtime", "Leaves", "Total Hours"]
              total_hours_sum = 0
              user.attendances.where(check_in_time: @start_date.beginning_of_day..@end_date.end_of_day).order(created_at: :asc).each do |attendance|
                total_hours = attendance.total_hours || 0
                regular_hours = total_hours > 28800 ? 28800 : total_hours
                overtime_hours = total_hours > 28800 ? total_hours - 28800 : 0
                sheet.add_row [
                  attendance.check_in_time&.strftime("%Y-%m-%d"),
                  attendance.check_in_time&.in_time_zone("Asia/Karachi").strftime("%I:%M"),
                  attendance.check_out_time&.in_time_zone("Asia/Karachi").strftime("%I:%M") || "N/A",
                  regular_hours / 3600,
                  overtime_hours / 3600,
                  current_user_leaves,
                  total_hours / 3600
                ]
                total_hours_sum += total_hours
              end
              sheet.add_row ["Total:", "", "", "", "", "", total_hours_sum / 3600]
    
              reg_hours = @total_working_hours - current_user_leaves * 8 if user.leaves.present?
              reg_hours ||= @total_working_hours
              working_hours = @total_hours[user.id] / 3600
              overtime_hours = working_hours > reg_hours ? working_hours - reg_hours : 0
              undertime = reg_hours > working_hours ? reg_hours - working_hours : 0
            end
          end
          send_data xlsx_package.to_stream.read, filename: "monthly_report_#{Date::MONTHNAMES[@month]}_#{@year}.xlsx", type: "application/xlsx", disposition: "attachment"
        end
      end
      return
    end
    
    

    def monthly_report
      if params[:selected_users].present?
        user_ids = params[:selected_users].map(&:to_i)
        @users = User.where(id: user_ids)
      else
        @users = User.active.where(role: "user", deleted: false).order(created_at: :desc)
      end
      @month = params[:month].to_i
      @year = params[:year].to_i
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @total_hours = {}
      @leaves = {}
      current_month_start = @start_date.beginning_of_month
      current_month_end = @end_date.end_of_month
      @public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", current_month_end, current_month_start)
      @users.each do |user|
        @user_sessions = user.attendances.where(check_in_time: @start_date.beginning_of_day..@end_date.end_of_day).order(created_at: :asc)
        total_hrs = 0
        @user_sessions.each do |attendance|
          total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
        end
        @total_hours[user.id] = total_hrs
        regular_hours_per_day = 8
        date_range = (@start_date..@end_date).to_a
        working_days = calculate_working_days(@start_date, @end_date)
        @public_holidays.each do |holiday|
          working_days -= (holiday.start_date..holiday.end_date).count
        end
        @current_leaves = Leave.where("start_date <= ? AND end_date >= ? AND status = ? AND user_id = ?", @end_date, @start_date, 1, user.id).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }
        @total_working_hours = working_days * regular_hours_per_day
        present_dates = @user_sessions.pluck(:check_in_time).map(&:to_date)
        created_date = user.created_at.to_date
        d_leaves = user.leaves.pluck(:start_date, :end_date)
        total_leave_days = d_leaves.sum { |start_date, end_date| (end_date.to_date - start_date.to_date).to_i + 1 }
        work_days = date_range.reject { |date| date.saturday? || date.sunday? }
        @leave_dates = d_leaves.flat_map { |start_date, end_date| (start_date.to_date..end_date.to_date).to_a }.uniq
        work_days -= @leave_dates
        working_days -= @leave_dates.count
        leaves_count = work_days.count do |date|
          !present_dates.include?(date) && date >= created_date && date <= Date.today
        end
        
        holidays = work_days.count - working_days
        if leaves_count == 0
          @leaves[user.id] = 0
        elsif leaves_count < holidays
          @leaves[user.id] = leaves_count
        else
          @leaves[user.id] = leaves_count - holidays
        end
      end
      if @user_sessions.present?
        respond_to do |format|
          format.html
          format.pdf { render pdf: "MonthlyReport_#{Date::MONTHNAMES[@month]}#{@year}", layout: false } # Specify view and disable layout
        end
      else
        flash[:error] = "Attendance Not Present"
        redirect_to admin_monthly_users_list_path(month: Date.today.month, year: Date.today.year)
      end
    end
    
    def monthly_users_list
      @users = User.active.where(role: "user", deleted: false).order(created_at: :desc)
      @month = params[:month].to_i
      @year = params[:year].to_i
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @total_hours = {}
      current_month_start = @start_date.beginning_of_month
      current_month_end = @end_date.end_of_month
      @public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", current_month_end, current_month_start)
      @users.each do |user|
        user_sessions = user.attendances.where(check_in_time: @start_date.beginning_of_day..@end_date.end_of_day).order(created_at: :asc)
        total_hrs = 0
        user_sessions.each do |attendance|
          total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
        end
        @total_hours[user.id] = total_hrs
        regular_hours_per_day = 8
        date_range = (@start_date..@end_date).to_a
        working_days = calculate_working_days(@start_date, @end_date)
        @public_holidays.each do |holiday|
          working_days -= (holiday.start_date..holiday.end_date).count
        end
        @current_leaves = Leave.where("start_date <= ? AND end_date >= ? AND status = ? AND user_id = ?", @end_date, @start_date, 1, user.id).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }
        @total_working_hours = working_days * regular_hours_per_day
      end
    end
    
    private
   
    def user_params
      params.require(:user).permit(:email, :name, :slack_member_id, :supervisor)
    end

    def disable_attendance(user)
      attendance = user.attendances.last
      if attendance.present?
        if attendance.check_out_time.nil?
          attendance.update(check_out_time: Time.now.utc)
          total_duration_seconds = attendance.check_out_time - attendance.check_in_time
          if attendance.break_in_time.present? && attendance.break_out_time.present?
            total_break = attendance.break_out_time - attendance.break_in_time
            total_duration_seconds -= total_break
          end
          attendance.update!(total_hours: total_duration_seconds)
          SlackService.new(user, "Checked Out", attendance.check_out_time).send_message
        end
      end
    end

    def calculate_working_days(start_date, end_date, public_holidays = [])
      start_date = Date.parse(start_date.to_s) rescue nil
      end_date = Date.parse(end_date.to_s) rescue nil
      return 0 unless start_date && end_date
      working_days = (start_date..end_date).to_a.reject do |date|
        date.saturday? || date.sunday?
      end
      working_days.length
    end
   end
   