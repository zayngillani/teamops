class Admin::UsersController < ApplicationController
  before_action :validate_email_format, only: [:create, :update]
  skip_before_action :authenticate_user!, only: [:complete_profile_step_one, :complete_profile_step_two, :complete_profile_step_three, :complete_profile_step_four, :complete_profile_step_five, :final_confirmation ]

    def index
      session = User.where(role: "user", deleted: false)
                    .order(name: :asc)
      @session = session.paginate(page: params[:page], per_page: 10)
      @all_users_same_status = session.pluck(:can_outside_access).uniq
    end
  
    def new
      @user = User.new
    end
   
    def create
      if validate_join_date(params[:user][:join_date])
        redirect_to new_admin_user_path, flash: { error: "Joining date must be a weekday and not a holiday. Please choose another date." }
        return
      end
        @existing_user = User.find_by(email: params[:user][:email])
        if @existing_user.present?
          flash[:error] = "Email Already Exists"
          redirect_to root_path
        else
          @user = User.new(user_params)
          @user.email = @user.generate_email
          @user.ip_address = "#{request.headers['X-Forwarded-For']&.split(',')&.last&.strip || request.ip || request.remote_ip}"
          @user.role = "user"
          if @user.save(validate: false)
            UserMailer.welcome_onboard_email(@user).deliver_now
            flash[:success] = "Employee added successfully"
            redirect_to root_path and return
          else
            render 'new'
          end
        end
    end

    def edit
      @user = User.find_by(id: params[:id]) if params[:id].present?
    end
    
    def update
      @user = User.find_by(id: params[:id])
      if @user.present?
        if validate_join_date(params[:user][:join_date])
          redirect_to edit_admin_user_path, flash: { error: "Joining date must be a weekday and not a holiday. Please choose another date." }
          return
        end
        if (params[:user][:password].present? && params[:user][:password_confirmation].present? && params[:user][:password] != params[:user][:password_confirmation]) ||
          (params[:user][:password].present? ^ params[:user][:password_confirmation].present?)
          redirect_to edit_admin_user_path, flash: { error: "Password and confirmation password do not match." }
          return
        end
        @user.update(user_params)
        if params[:user][:password].present?
          @user.update!(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
        end
        flash[:success] = "User updated successfully"
        redirect_to root_path and return
      else
        flash[:error] = "User not found"
      end
    end

    def user_profile
      @user = current_user if current_user.present?
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
        flash[:error] = "Attendance not Present"
        redirect_to admin_report_path and return
      end
    end
    

    def destroy
      @user = User.find_by(id: params[:id])
      if @user.deleted == false
        @user.update(deleted: true)
        flash[:success] = "Employee has been deleted"
      elsif @user.deleted == true
        @user.update(deleted: false)
        flash[:success] = "Employee Unarchived Successfully"
      else
        flash[:error] = "Employee already Deleted"
      end
      redirect_to root_path
    end

    def disable_user
      @user = User.find_by(id: params[:id])
      if @user.present?
        if @user.status == "active"
          @user.update(status: 1)
          disable_attendance(@user)
          flash[:success] = "Employee has been disabled"
          redirect_to admin_users_path
        elsif @user.status == "pending"
          @user.update(status: 0)
          flash[:success] = "Employee has been disabled"
          redirect_to admin_users_path
        else
          flash[:error] = "Employee already Disabled"
          redirect_to admin_users_path
        end
      else
        flash[:error] = "User Not Found"
        redirect_to admin_users_path
      end
    end

    def report
      session = User.active.where(role: "user", deleted: false).order(name: :asc)
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

    def archived_user
      @users = User.where(role: "user", deleted: 1).order(name: :asc).paginate(page: params[:page], per_page: 10)
    end

    def user_leave
      @user = User.find_by(id: params[:id])
      @month = params[:month].to_i
      @year = params[:year].to_i
      @users = User.active.where(role: "user", deleted: false).order(name: :asc)
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", @end_date, @start_date)
      @total_days = calculate_working_days(@start_date, @end_date)
    end

    def leave_report
      @month = params[:month].to_i
      @year = params[:year].to_i
      @users = User.active.where(role: "user", deleted: false).order(name: :asc)
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", @start_date.end_of_month, @end_date.beginning_of_month)
      @user_leaves = {}
      @total_days = calculate_working_days(@start_date, @end_date)
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
      @month = params[:month].to_i
      @year = params[:year].to_i
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @users = fetch_users
      @total_hours = {}
      @public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", @end_date, @start_date)
      @users.each do |user|
        @user_sessions = user.attendances.where(check_in_time: @start_date.beginning_of_day..@end_date.end_of_day).order(created_at: :asc)
        total_hrs = 0
        @user_sessions.each do |attendance|
          selected_columns = params[:selected_columns].split(',')
          if selected_columns.include?("include_break")
            total_hrs += attendance.total_hours.to_i + attendance.total_break.to_i unless attendance.total_hours.nil?
          else
            total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
          end
        end
        @total_hours[user.id] = total_hrs
        regular_hours_per_day = 8
        date_range = (@start_date..@end_date).to_a
        working_days = calculate_working_days(@start_date, @end_date)
        @total_days = working_days
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
          if columns_to_include[7] == "include_break" || columns_to_include[7] == "exclude_break"
            @break_column = columns_to_include.pop
          else
            @break_column = "exclude_break"
          end
          wb.add_worksheet(name: "Monthly Report") do |sheet|
            styles = wb.styles
            header_style = styles.add_style(b: true)
            bold_style = styles.add_style(b: true)
            headers = ["Name"]
            headers += columns_to_include.map(&:humanize)
            sheet.add_row headers, style: header_style
            total_expected_hours ||= 0
            total_regular_hours ||= 0
            total_worked_hours ||= 0
            total_overtime_hours ||= 0
            total_undertime_hours ||= 0
            total_leaves ||= 0
            total_absentees ||= 0
            @users.each do |user|
              current_user_leaves = Leave.where("start_date <= ? AND end_date >= ? AND status = ? AND user_id = ?", @end_date, @start_date, 1, user.id).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }
              reg_hours = user.leaves.present? ? (@total_working_hours - current_user_leaves * 8) : @total_working_hours
              @regular_hours = reg_hours
              working_hours = @total_hours[user.id] / 3600
              overtime = @regular_hours < working_hours ? (working_hours - @regular_hours) : 0
              undertime = @regular_hours > working_hours ? (@regular_hours - working_hours) : 0
              user_creation_date = user.created_at.to_date
              first_day_of_month = Date.new(@year, @month, 1)
              last_day_of_month = (@month == Date.today.month && @year == Date.today.year) ? Date.today : @end_date
              adjusted_start_date = user_creation_date.month == @month && user_creation_date.year == @year ? user_creation_date : first_day_of_month
              total_days_range = (adjusted_start_date..last_day_of_month).to_a
              @total_days = total_days_range.reject { |date| date.saturday? || date.sunday? }.count
              if @public_holidays.present?
                @public_holidays.each do |holiday|
                  if holiday.start_date >= user_creation_date
                    @total_days -= (holiday.start_date..holiday.end_date).count
                  end
                end
              end
              @current_user_leaves = Leave.where("start_date <= ? AND end_date >= ? AND status = ? AND user_id = ?", @end_date, @start_date, 1, user.id).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }
              @attendance_data = user.attendances.where(check_in_time: @start_date.beginning_of_day..@end_date.end_of_day)
              @attendance_days = @attendance_data.count
              @public_holidays_count = @public_holidays.count
              reg_hours = user.leaves.present? ? (@total_working_hours - @current_user_leaves * 8) : @total_working_hours
              reg_seconds = reg_hours * 3600
              total_seconds = @total_hours[user.id] || 0
              working_hours = total_seconds / 3600
              working_minutes = (total_seconds % 3600) / 60
              overtime_hours = 0
              overtime_minutes = 0
              undertime_hours = 0
              undertime_minutes = 0        
              if total_seconds > reg_seconds
                remaining_overtime_seconds = total_seconds - reg_seconds          
                overtime_hours = remaining_overtime_seconds / 3600
                overtime_minutes = (remaining_overtime_seconds % 3600) / 60
              else
                overtime_hours = 0
                overtime_minutes = 0
              end        
              if total_seconds < reg_seconds
                remaining_seconds = reg_seconds - total_seconds          
                undertime_hours = remaining_seconds / 3600
                undertime_minutes = (remaining_seconds % 3600) / 60
              else
                undertime_hours = 0
                undertime_minutes = 0
              end
              overtime_minutes ||= 0
              undertime_minutes ||= 0
              formatted_working_time = "%02d:%02d" % [working_hours, working_minutes]
              formatted_overtime = "%02d:%02d" % [overtime_hours, overtime_minutes]
              formatted_undertime = "%02d:%02d" % [undertime_hours, undertime_minutes]
              absentee_days = [@total_days - (@attendance_days + @current_user_leaves), 0].max
              total_expected_hours += @total_working_hours
              total_regular_hours += reg_hours
              total_worked_hours += total_seconds / 3600.0
              total_overtime_hours += overtime_hours + overtime_minutes / 60.0
              total_undertime_hours += undertime_hours + undertime_minutes / 60.0
              total_leaves += @current_user_leaves
              total_absentees += absentee_days
              data_row = [user.name]
              columns_to_include.each do |column|
                case column
                when 'expected_hours'
                  data_row << @total_working_hours
                when 'regular_hours'
                  data_row << reg_hours
                when 'worked_hours'
                  data_row << formatted_working_time
                when 'over_time'
                  data_row << formatted_overtime
                when 'under_time'
                  data_row << formatted_undertime
                when 'leaves'
                  data_row << current_user_leaves
                when 'absentees'
                  data_row << absentee_days
                end
              end
              sheet.add_row data_row
            end
              totals_row = ['Total']
              columns_to_include.each do |column|
                case column
                when 'expected_hours'
                  totals_row << total_expected_hours
                when 'regular_hours'
                  totals_row << total_regular_hours
                when 'worked_hours'
                  total_worked_minutes = (total_worked_hours * 60).to_i % 60
                  total_worked_hours_formatted = "%02d:%02d" % [total_worked_hours.to_i, total_worked_minutes]
                  totals_row << total_worked_hours_formatted
                when 'over_time'
                  total_overtime_minutes = (total_overtime_hours * 60).to_i % 60
                  total_overtime_hours_formatted = "%02d:%02d" % [total_overtime_hours.to_i, total_overtime_minutes]
                  totals_row << total_overtime_hours_formatted
                when 'under_time'
                  total_undertime_minutes = (total_undertime_hours * 60).to_i % 60
                  total_undertime_hours_formatted = "%02d:%02d" % [total_undertime_hours.to_i, total_undertime_minutes]
                  totals_row << total_undertime_hours_formatted
                when 'leaves'
                  totals_row << total_leaves
                when 'absentees'
                  totals_row << total_absentees
                end
              end
              sheet.add_row totals_row, style: bold_style
            end
          @users.each do |user|
            wb.add_worksheet(name: "#{user.name}_#{user.id}") do |sheet|
              styles = wb.styles
              header_style = wb.styles.add_style(b: true)
              entry_style = wb.styles.add_style(b: true, alignment: { horizontal: :center })
              session_style = wb.styles.add_style(alignment: { horizontal: :center })
                sheet.add_row ["Date", "Check In", "Check Out", "Regular Hours", "Overtime", "Leaves", "On Call" ,"Total Hours"], style: header_style
                total_hours_sum = 0
              total_oncall_hours = 0
              total_regular_hours = 0
              total_overtime_hours = 0
              total_break_hours = 0
              public_holidays = {}
              @public_holidays.each do |holiday|
                (holiday.start_date..holiday.end_date).each do |date|
                  public_holidays[date] = holiday.title
                end
              end
              leaves = {}
              user_leaves = Leave.where("start_date <= ? AND end_date >= ? AND status = ? AND user_id = ?", @end_date, @start_date, 1, user.id)
              user_leaves.each do |leave|
                (leave.start_date..leave.end_date).each do |date|
                  leaves[date] = leave
                end
              end
              on_calls = {}
              user_on_calls = Oncall.where('(start_date <= ? AND end_date >= ?) OR (start_date >= ? AND start_date <= ?)', @end_date, @start_date, @start_date, @end_date).where(request_status: 1, user_id: user.id)
              user_on_calls.each do |oncall|
                (oncall.start_date..oncall.end_date).each do |date|
                  on_calls[date] = date
                end
              end
              (@start_date..@end_date).each do |date|
                is_weekend = date.saturday? || date.sunday?
                attendance = user.attendances.find_by(check_in_time: date.beginning_of_day..date.end_of_day)
                if @break_column.include?("include_break")
                  total_hours = attendance.present? ? (attendance.total_hours.to_i + attendance.total_break.to_i || 0) : 0
                else
                  total_hours = attendance.present? ? (attendance.total_hours || 0) : 0
                end
                total_break = attendance.present? ? (attendance.total_break || 0) : 0
                if attendance.present?
                  regular_hours = total_hours > 28800 ? 28800 : total_hours
                  overtime_hours = total_hours > 28800 ? total_hours - 28800 : 0
                  formatted_reg_hours = format_time(regular_hours)
                  formatted_total_hours = format_time(total_hours)
                  formatted_overtime_hours = format_time(overtime_hours)
                end
                total_break_hours += total_break if total_break.present?
                total_regular_hours += regular_hours if regular_hours.present?
                total_overtime_hours += overtime_hours if overtime_hours.present?
                is_public_holiday = public_holidays.key?(date)
                is_leave = leaves.key?(date)
                is_oncall = on_calls.key?(date)
                if is_oncall
                  sheet.add_row [
                    date.strftime("%A %b #{date.day.ordinalize}"),
                    attendance.present? && attendance.check_in_time.present? ? attendance.check_in_time.in_time_zone("Asia/Karachi").strftime("%I:%M %p") : "N/A",
                    attendance.present? && attendance.check_out_time.present? ? attendance.check_out_time.in_time_zone("Asia/Karachi").strftime("%I:%M %p") : "N/A",
                    attendance.present? ? formatted_reg_hours : "N/A",
                    attendance.present? ? formatted_overtime_hours : "N/A",
                    "On Call",
                    "",
                    attendance.present? ? formatted_total_hours : "N/A"
                  ], style: [nil, nil, nil, nil, entry_style, nil, nil, nil]
                  total_oncall_hours += total_hours if total_hours.present?
                elsif is_public_holiday
                  sheet.add_row [
                    date.strftime("%A %b #{date.day.ordinalize}"),
                    "","","","",
                    "#{public_holidays[date]}",
                    "","",
                  ], style: [nil, nil, nil, nil, nil, entry_style, nil, nil]
                elsif is_leave
                  sheet.add_row [
                    date.strftime("%A %b #{date.day.ordinalize}"),
                    "","","",
                    leaves[date]&.emergency ? "Emergency Leave" : leaves[date].leave_type == 'wedding' ? "Wedding Leave" : "On Leave","",
                    "","",
                  ], style: [nil, nil, nil, nil, entry_style, nil, nil, nil]
                elsif attendance
                  sheet.add_row [
                    date.strftime("%A %b #{date.day.ordinalize}"),
                    attendance.check_in_time.present? ? attendance.check_in_time.in_time_zone("Asia/Karachi").strftime("%I:%M %p") : "N/A",
                    attendance.check_out_time.present? ? attendance.check_out_time.in_time_zone("Asia/Karachi").strftime("%I:%M %p") : "N/A",
                    attendance.total_hours.present? ? formatted_reg_hours : "N/A",
                    attendance.total_hours.present? ? formatted_overtime_hours : "N/A",
                    "","",
                    attendance.total_hours.present? ? formatted_total_hours : "N/A"
                  ]                  
                  total_hours_sum += total_hours
                else
                  next if is_weekend
                  sheet.add_row [
                    date.strftime("%A %b #{date.day.ordinalize}"),
                    "","","",
                    "No Session",
                    "","","",""
                  ], style: [nil, nil, nil, nil, session_style, nil, nil]
                end
              end
              time_format = format_time(@total_hours[user.id])
              oncall_hours = format_time(total_oncall_hours)
              regular = format_time(total_regular_hours)
              overtime = format_time(total_overtime_hours)
                sheet.add_row ["Total:", "", "", regular, overtime, user_leaves.sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }, oncall_hours ,time_format], style: header_style
              reg_hours = @total_working_hours - user_leaves.sum { |leave| (leave.end_date - leave.start_date).to_i + 1 } * 8 if user_leaves.present?
              reg_hours ||= @total_working_hours
              working_hours = @total_hours[user.id] / 3600
              overtime_hours = working_hours > reg_hours ? working_hours - reg_hours : 0
              undertime = reg_hours > working_hours ? reg_hours - working_hours : 0
            end
          end
            send_data xlsx_package.to_stream.read, filename: "monthly_report_#{Date::MONTHNAMES[@month]}_#{@year}.xlsx", type: "application/xlsx", disposition: "attachment"
        end
      end
    end
    

    def monthly_report
      @month = params[:month].to_i
      @year = params[:year].to_i
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @users = fetch_users
      @total_hours = {}
      @leaves = {}
      current_month_start = @start_date.beginning_of_month
      current_month_end = @end_date.end_of_month
      @selected_columns = params[:selected_columns].split(',') || []

      @public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", current_month_end, current_month_start)

      @users.each do |user|
        @user_sessions = user.attendances.where(check_in_time: @start_date.beginning_of_day..@end_date.end_of_day).order(created_at: :asc)
        total_hrs = 0
        @user_sessions.each do |attendance|
          if @selected_columns.include?("breaks")
            total_hrs += attendance.total_hours.to_i + attendance.total_break.to_i unless attendance.total_hours.nil?
          else
            total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
          end
        end
        @total_hours[user.id] = total_hrs

        regular_hours_per_day = 8
        date_range = (@start_date..@end_date).to_a
        working_days = calculate_working_days(@start_date, @end_date)
        @total_days = working_days

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

        absences_count = work_days.count { |date| !present_dates.include?(date) && date >= created_date && date <= Date.today }
        holidays = work_days.count - working_days

        if absences_count == 0
          @leaves[user.id] = 0
        elsif leaves_count < holidays
          @leaves[user.id] = absences_count
        else
          @leaves[user.id] = absences_count - @public_holidays.count
        end
      end

        respond_to do |format|
          format.html
          format.pdf do
            render pdf: "MonthlyReport_#{Date::MONTHNAMES[@month]}#{@year}",
                   layout: false, # Specify view and disable layout
                   locals: { selected_columns: @selected_columns }
          end
        end
    end

    def monthly_users_list
      @month = params[:month].to_i
      @year = params[:year].to_i
      @start_date = Date.new(@year, @month, 1)
      @end_date = @start_date.end_of_month
      @users = fetch_users
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
      
    def update_ip_restriction
      user = User.find_by(id: params[:id])
      
      if user.nil?
        render json: { success: false, errors: ["User not found"] }, status: :not_found
        return
      end
    
      if user.update(can_outside_access: params[:can_outside_access])
        render json: { success: true }, status: :ok
      else
        render json: { success: false, errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update_all_ip_restrictions
      can_outside_access = params[:can_outside_access]
      if User.where(role: "user").update_all(can_outside_access: can_outside_access)
        render json: { success: true }
      else
        render json: { success: false }, status: :unprocessable_entity
      end
    end

    def complete_profile_step_one
      @user = User.find(params[:id])
    end

    def complete_profile_step_two
      @user = User.find(params[:id])
      
      # Fetch the password from params and validate it
      password = params[:user][:password]
      if password_valid?(password)
        @user.update(user_profile_params)
        # Call On-Boarding procedure 
        onboard_accounts(@user.email, password) if Rails.env.production?
        redirect_to complete_profile_instructions_admin_user_path(@user), notice: "Profile updated successfully."
      else
        redirect_to complete_profile_admin_user_path
      end
    end
    
    def complete_profile_step_three
      @user = User.find(params[:id])
    end
  
    def complete_profile_step_four
      @user = User.find(params[:id])
    end
  
    def complete_profile_step_five
      @user = User.find(params[:id])
      if @user.update(slack_member_id: params[:user][:slack_member_id], github_user_name: params[:user][:github_user_name])
        flash[:alert] = "Your slack id and github username has been submitted successfully"
        redirect_to final_confirmation_admin_user_path
      else
        flash[:alert] = "Something  went wrong!"
        redirect_to submit_information_admin_user_path
      end
    end
  
    def final_confirmation
      @user = User.find(params[:id])
    end
    
    private
   
    def user_params
      params.require(:user).permit(:personal_email, :name, :supervisor, :join_date, :is_github_required)
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

    def format_total_time(total_seconds)
      hours = total_seconds / 3600
      minutes = (total_seconds % 3600) / 60
      "%02d.%02d" % [hours, minutes]
    end

    def format_time(total_seconds)
      hours = total_seconds / 3600
      minutes = (total_seconds % 3600) / 60
      "#{hours} hours #{minutes} minutes"
    end

    def validate_email_format
      unless params[:user][:personal_email] =~ /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/
        flash[:error] = "Invalid Email Format"
        redirect_to root_path
      end
    end

    def validate_join_date(join_date_str)
      join_date = join_date_str.to_date
      current_month = join_date.month
      current_year = join_date.year
      joining_date = Date.parse(join_date_str)
      holidays = PublicHoliday.where(
        "(EXTRACT(MONTH FROM start_date) = ? AND EXTRACT(YEAR FROM start_date) = ?) OR 
        (EXTRACT(MONTH FROM end_date) = ? AND EXTRACT(YEAR FROM end_date) = ?)",
        current_month, current_year, current_month, current_year
      )
      holiday_present = holidays.any? { |holiday| (holiday.start_date..holiday.end_date).cover?(join_date) }
      if holiday_present || joining_date.saturday? || joining_date.sunday?
        return true
      end
      false
    end

    def fetch_users
      if params[:selected_users].present?
        user_ids = params[:selected_users].split(',')
        @users = User.where(id: user_ids).where('join_date <= ?', @end_date.end_of_day).order(name: :asc)
      else
        User.active.where(role: "user", deleted: false).where('join_date <= ?', @end_date.end_of_day).order(name: :asc)
      end
    end

    def user_profile_params
      params.require(:user).permit(:address, :phone_number, :emergency_phone_number, :cnic, :date_of_birth, :password, :password_confirmation)
    end
  
    def password_valid?(password)
      password.match?(/\A[a-zA-Z0-9-]+\z/)
    end
  
    def disable_attendance(user)
      # Attempt to offboard the user
      deactivate = offboard_accounts(user)
  
      # Check if the offboarding process was successful
      if deactivate[:success] == false
        puts "Offboarding failed for user #{user.email}: #{deactivate[:error]}"
        return deactivate
      else
        begin
          # Update user's status to 1 (assuming '1' means deactivated)
          user.update!(status: 1)
          puts "User status updated to deactivated"
  
          # Get the last attendance record for the user
          attendance = user.attendances.last
  
          if attendance.present?
            # Check if the user hasn't checked out yet
            if attendance.check_out_time.nil?
              attendance.update!(check_out_time: Time.now.utc)
              total_duration_seconds = attendance.check_out_time - attendance.check_in_time
  
              # Calculate the total break time if applicable
              if attendance.break_in_time.present? && attendance.break_out_time.present?
                total_break = attendance.break_out_time - attendance.break_in_time
                total_duration_seconds -= total_break
              end
  
              # Update the total worked hours
              attendance.update!(total_hours: total_duration_seconds)
              puts "Attendance updated with total hours"
  
              # Send Slack notification about checkout
              SlackService.new(user, "Checked Out", attendance.check_out_time).send_message
              puts "Slack notification sent"
            else
              puts "User has already checked out"
            end
          else
            puts "No attendance record found for user #{user.email}"
            return { success: false, error: "No attendance record found" }
          end
  
          # If everything goes well, return success
          return { success: true }
  
          # Handle any exceptions that may occur during the process
        rescue StandardError => e
          puts "Error occurred while processing attendance: #{e.message}"
          return { success: false, error: "Error occurred while processing attendance", details: e.message }
        end
      end
    end

    def onboard_accounts(email, password)
      # Webmail cPanel Email Creation
      begin
        # cpanel_uri = URI("https://techcreatix.com:2083/execute/Email/add_pop?email=#{email}&password=#{password}")
        # cpanel_request = Net::HTTP::Get.new(cpanel_uri)
        # cpanel_request['Authorization'] = ENV['CPANEL_AUTH']
  
        # cpanel_response = Net::HTTP.start(cpanel_uri.hostname, cpanel_uri.port, use_ssl: true) do |http|
        #   http.request(cpanel_request)
        # end
  
        # raise StandardError, "Failed to create cPanel email: #{cpanel_response.body}" unless cpanel_response.is_a?(Net::HTTPSuccess)
      webmail_response = enable_email(user,password)
      if webmail_response[:success] == false
        puts "Failed to disable Webmail for user #{email}: #{webmail_response[:error]}"
        return { success: false, error: "Failed to create Webmail", details: webmail_response[:error] }
      else
        puts "Successfully disabled Webmail for user #{email}"
      end
      rescue => e
        puts "Error during cPanel email creation: #{e.message}"
        message = "Failed to create webmail email:"
        OnboardSlackService.new(message, email).send_onboard_alert
        return { success: false, error: "Webmail creation failed: #{e.message}" }
      end
  
      # GitHub Invitation
      if @user.is_github_required?
        begin
          github_uri = URI("https://api.github.com/orgs/techcreatix-team/invitations")
          github_request = Net::HTTP::Post.new(github_uri)
          github_request['Authorization'] = "Bearer #{ENV['GITHUB_TOKEN']}"
          github_request['Accept'] = 'application/vnd.github.v3+json'
          github_request.body = { email: email }.to_json
  
          github_response = Net::HTTP.start(github_uri.hostname, github_uri.port, use_ssl: true) do |http|
            http.request(github_request)
          end
  
          raise StandardError, "Failed to send GitHub invite: #{github_response.body}" unless github_response.is_a?(Net::HTTPSuccess)
        rescue => e
          puts "Error during GitHub invitation: #{e.message}"
          return { success: false, error: "GitHub invitation failed: #{e.message}" }
        end
      end
  
      # Slack Invitation
      begin
        slack_uri = URI("https://slack.com/api/users.admin.invite")
        slack_request = Net::HTTP::Post.new(slack_uri)
        slack_request['Authorization'] = "Bearer #{ENV['SLACK_TOKEN']}"
        slack_request['Content-Type'] = 'application/x-www-form-urlencoded'
        slack_request.set_form_data(email: email)
  
        slack_response = Net::HTTP.start(slack_uri.hostname, slack_uri.port, use_ssl: true) do |http|
          http.request(slack_request)
        end
  
        raise StandardError, "Failed to send Slack invite: #{slack_response.body}" unless slack_response.is_a?(Net::HTTPSuccess)
      rescue => e
        puts "Error during Slack invitation: #{e.message}"
        return { success: false, error: "Slack invitation failed: #{e.message}" }
      end
  
      # If all processes succeeded
      return { success: true, message: "All invitations sent successfully." }
    end
  
    def offboard_accounts(user)
      # Function to disable Webmail for a specific User
      webmail_response = disable_email(user)
      if webmail_response[:success] == false
        puts "Failed to disable Webmail for user #{user.email}: #{webmail_response[:error]}"
        return { success: false, error: "Failed to disable Webmail", details: webmail_response[:error] }
      else
        puts "Successfully disabled Webmail for user #{user.email}"
      end
  
      # Function to disable GitHub for a specific User
      collaborator = "#{user.name.split(' ').first.downcase}-tx"
      github_response = disable_github(ENV['GITHUB_TOKEN'], ENV['GITHUB_USER'], collaborator)
      if github_response[:success] == false
        puts "Failed to disable GitHub access for collaborator #{collaborator}: #{github_response[:error]}"
        return { success: false, error: "Failed to disable GitHub", details: github_response[:error] }
      else
        puts "Successfully disabled GitHub access for collaborator #{collaborator}"
      end
  
      # Function to disable Slack for a specific User (if implemented)
      # slack_response = remove_user_from_channels(user.slack_member_id)
      # if slack_response[:success] == false
      #   puts "Failed to remove user from Slack channels: #{slack_response[:error]}"
      #   return { success: false, error: "Failed to disable Slack", details: slack_response[:error] }
      # else
      #   puts "Successfully removed user from Slack channels"
      # end
  
      # If all operations succeed
      return { success: true, message: "User offboarding completed successfully" }
    end
  
    # Function to get all repositories
    def get_repos(base_url, github_token, github_user, per_page, page)
      response = HTTParty.get("#{base_url}/user/repos", query: { per_page: per_page, page: page }, headers: {
        "Authorization" => "Bearer #{github_token}",
        "User-Agent" => github_user
      })
      response.parsed_response
    end
  
    # Function to get collaborators for a specific repository
    def get_collaborators(base_url, github_token, github_user, owner, repo)
      response = HTTParty.get("#{base_url}/repos/#{owner}/#{repo}/collaborators", headers: {
        "Authorization" => "Bearer #{github_token}",
        "User-Agent" => github_user
      })
      if response.code == 404
        # Repository or collaborators not found
        puts "Repository or collaborators not found for #{owner}/#{repo}"
        return []
      else
        response.parsed_response
      end
    end
  
    # Function to remove a collaborator from a repository
    def remove_collaborator(base_url, github_token, github_user, owner, repo, collaborator)
      response = HTTParty.delete("#{base_url}/repos/#{owner}/#{repo}/collaborators/#{collaborator}", headers: {
        "Authorization" => "Bearer #{github_token}",
        "User-Agent" => github_user
      })
      response
    end
  
    def disable_email(user)
      # Define the cPanel URI and make the GET request with HTTParty
      cpanel_uri = "https://techcreatix.com:2083/execute/Email/add_pop?email=#{user.email}&password=Techcreatix-2019"
  
      begin
        # Use HTTParty to send the request
        cpanel_response = HTTParty.get(
          cpanel_uri,
          headers: { "Authorization" => ENV['CPANEL_AUTH'] }
        )
  
        # Check the HTTP status code
        if cpanel_response.code == 200
          begin
            # Attempt to parse the response body as JSON
            response_body = JSON.parse(cpanel_response.body)
  
            # Check if there are errors in the response body
            if response_body["errors"]
              puts "Error: #{response_body['errors']}"
              return { success: false, error: response_body['errors'] }
            else
              puts "Successfully disabled email for #{user.email}"
              return { success: true }
            end
          rescue JSON::ParserError => e
            # Handle case where response body is not valid JSON
            puts "Error: Unable to parse response body as JSON. Response: #{cpanel_response.body}"
            return { success: false, error: "Invalid JSON response: #{e.message}" }
          end
        else
          # If the status code is not 200, log the failure with status code
          puts "Failed with status code: #{cpanel_response.code}. Response body: #{cpanel_response.body}"
          return { success: false, error: "Failed request with status code: #{cpanel_response.code}" }
        end
      rescue StandardError => e
        # Handle general network or request errors
        puts "Request failed: #{e.message}"
        return { success: false, error: "Request failed: #{e.message}" }
      end
    end

    def enable_email(user,password)
      # Define the cPanel URI and make the GET request with HTTParty
      cpanel_uri = "https://techcreatix.com:2083/execute/Email/add_pop?email=#{user.email}&password=#{password}"
  
      begin
        # Use HTTParty to send the request
        cpanel_response = HTTParty.get(
          cpanel_uri,
          headers: { "Authorization" => ENV['CPANEL_AUTH'] }
        )
  
        # Check the HTTP status code
        if cpanel_response.code == 200
          begin
            # Attempt to parse the response body as JSON
            response_body = JSON.parse(cpanel_response.body)
  
            # Check if there are errors in the response body
            if response_body["errors"]
              puts "Error: #{response_body['errors']}"
              return { success: false, error: response_body['errors'] }
            else
              puts "Successfully disabled email for #{user.email}"
              return { success: true }
            end
          rescue JSON::ParserError => e
            # Handle case where response body is not valid JSON
            puts "Error: Unable to parse response body as JSON. Response: #{cpanel_response.body}"
            return { success: false, error: "Invalid JSON response: #{e.message}" }
          end
        else
          # If the status code is not 200, log the failure with status code
          puts "Failed with status code: #{cpanel_response.code}. Response body: #{cpanel_response.body}"
          return { success: false, error: "Failed request with status code: #{cpanel_response.code}" }
        end
      rescue StandardError => e
        # Handle general network or request errors
        puts "Request failed: #{e.message}"
        return { success: false, error: "Request failed: #{e.message}" }
      end
    end
  
    def disable_github(github_token, github_user, collaborator)
      base_url = "https://api.github.com"
      page = 1
      per_page = 100
      puts "Checking collaborator: #{collaborator}"
  
      # Fetch repositories for the user
      repos_response = get_repos(base_url, github_token, github_user, per_page, page)
  
      # Handle case where repositories are not found or error occurred
      if repos_response.nil? || repos_response.empty?
        puts "Error: No repositories found for user #{github_user}."
        return { success: false, error: "No repositories found for user #{github_user}." }
      end
  
      repos_response.each do |repo|
        owner = repo['owner']['login']
        repo_name = repo['name']
        puts "Checking collaborators for repo: #{repo_name}"
  
        # Fetch collaborators for the repo
        collaborators_response = get_collaborators(base_url, github_token, github_user, owner, repo_name)
  
        # Handle case where collaborators are not found or error occurred
        if collaborators_response.nil?
          puts "Error: Could not fetch collaborators for #{repo_name}. Skipping this repo."
          next
        end
  
        collaborator_names = collaborators_response.map { |collab| collab['login'] }
  
        # Check if the collaborator is present in the repo
        if collaborator_names.include?(collaborator)
          puts "Found #{collaborator} in #{repo_name}. Removing..."
  
          # Remove the collaborator from the repository
          remove_response = remove_collaborator(base_url, github_token, github_user, owner, repo_name, collaborator)
  
          # Handle successful and failed removal
          if remove_response.code == 204
            puts "Successfully removed #{collaborator} from #{repo_name}"
          else
            puts "Failed to remove #{collaborator} from #{repo_name}. Error: #{remove_response.message}"
            return { success: false, error: "Failed to remove #{collaborator} from #{repo_name}. Error: #{remove_response.message}" }
          end
        else
          puts "#{collaborator} not found in #{repo_name}. Skipping..."
        end
      end
  
      # Return success if all repos were processed without any errors
      { success: true, message: "Successfully processed all repositories." }
    end
   end
   