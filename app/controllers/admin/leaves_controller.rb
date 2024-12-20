class Admin::LeavesController < ApplicationController
  include LeavesHelper
     before_action :set_month_and_year, only: [:index, :get_emergency_leaves]
     def index
          status = params[:status].present? ? params[:status].to_i : nil
          @leaves = Leave.where("start_date <= ? AND end_date >= ?", @current_month_end, @current_month_start)
          if status
            @leaves = @leaves.where(status: status)
          end
          @leaves = @leaves.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
     end

     def show
          @leave = Leave.find_by(id: params[:id])
          @user = User.find_by(id: @leave.user_id)
          @leave_days_count = (@leave.end_date - @leave.start_date).to_i + 1
     end

     def update
          @leave = Leave.find_by(id: params[:id])
          @user = @leave.user
          current_year_start, current_year_end = determine_leave_period(@leave.leave_type, @leave)
          leave_days = (@leave.end_date - @leave.start_date).to_i + 1
          annual_leaves = calculate_annual_leaves_count(current_year_start, current_year_end)
          unused_quarterly_leaves = calculate_unused_quarterly_leaves(current_year_start.year, @user)
          allotted_annual_leaves = @user.join_date > 1.year.ago ? '0' : ENV['ANNUAL_LEAVE'].to_i
          if params[:leave][:action_type] == "approve"
            if exceeds_leave_limit?(@leave.leave_type, leave_days, current_year_start, current_year_end, @user.id, annual_leaves, unused_quarterly_leaves, allotted_annual_leaves)
              error_message = case @leave.leave_type
                              when 'annual'
                                "#{@user.name} has exceeded the maximum annual leave limit of 8 days per year"
                              when 'quarterly'
                                "#{@user.name} has exceeded the maximum quarterly leave limit of 3 days per quarter"
                              end
              redirect_to admin_leaves_path, flash: { error: error_message }
              return
            end
               if params[:leave].present?
                    supervisor = params[:leave][:supervisor]
               else
                    supervisor = nil
               end
               if supervisor.present? && @leave.status == "pending"
                    @leave.update!(supervisor: supervisor, status: 1 )
                    SlackService.new(current_user, "#{@leave.leave_type.capitalize} Leave approved by", @leave).send_leave
                    message = "#{@leave.leave_type.capitalize} Leave Approved"
               else
                    message = "Leave not found"
               end
          else
               if @leave.present? && @leave.status == "pending"
                    @leave.update!(status: 2, supervisor: params[:leave][:supervisor].present? ? params[:leave][:supervisor] : nil)
                    error = "#{@leave.leave_type.capitalize} Leave Rejected"
               else @oncall.request_status == 2
                    message = "Leave not found"
               end
          end
               if message
                    flash[:success] = message
               else
                    flash[:error] = error
               end
               redirect_to admin_leaves_path
     end

     def get_emergency_leaves
          @leaves = Leave.where("start_date <= ? AND end_date >= ? AND emergency = ?", @current_month_end, @current_month_start, true).paginate(page: params[:page], per_page: 10)
     end

     def new_emergency_leaves
          @users = User.where(role: "user", deleted: false).order(name: :asc).paginate(page: params[:page], per_page: 10)
     end

     def create_emergency_leaves
          selected_user = params[:selected_user_id]
          leave_type = params[:leave_type]
          reason = params[:reason]
          selected_date = Date.parse(params[:selected_date]) rescue nil
          @user = User.find_by(id: selected_user)
          one_year_anniversary = @user.join_date + 3.months
          quarterly_restricted = @user.join_date + 3.months
          return if validate_emergency_leaves(selected_user, selected_date) ||
                    validate_existing_leaves(selected_user, selected_date) ||
                    validate_leave_limits(selected_user, leave_type) ||
                    invalid_leave_request?(selected_date, leave_type, one_year_anniversary, quarterly_restricted)
        
          @leave = Leave.create(user_id: selected_user, status: 1, reason: reason, leave_type: leave_type, start_date: selected_date, end_date: selected_date, supervisor: "Admin", emergency: true)
          SlackService.new(@leave.user, "Emergency Leave Created by Admin from", @leave).emergency_leave
          redirect_to get_emergency_leaves_admin_leaves_path, flash: { success: "Emergency Leave Created Successfully." }
     end

     private

     def set_month_and_year
          @month = params[:month].present? ? params[:month].to_i : Date.today.month
          @year = params[:year].present? ? params[:year].to_i : Date.today.year
          @start_date = Date.new(@year, @month, 1)
          @end_date = @start_date.end_of_month
          @current_month_start = @start_date.beginning_of_month
          @current_month_end = @end_date.end_of_month
     end

     def validate_emergency_leaves(selected_user, selected_date)
          return false unless selected_date
        
          emergency_start_date = Date.new(selected_date.year, selected_date.month, 1)
          emergency_end_date = emergency_start_date.end_of_month
          emergency_leaves_check = Leave.where(user_id: selected_user, status: 1, emergency: true)
                                  .where("start_date <= ? AND end_date >= ?", emergency_end_date, emergency_start_date)
        
          if emergency_leaves_check.present?
            flash[:error] = "The selected employee has already marked emergency leave for this month. Please select a different month or employee."
            redirect_to new_emergency_leaves_admin_leaves_path and return true
          end
        
          false
        end
        
        def validate_existing_leaves(selected_user, selected_date)
          existing_leaves = Leave.where(user_id: selected_user, status: [0, 1])
                                 .where("start_date <= ? AND end_date >= ?", selected_date, selected_date)
        
          if existing_leaves.present?
            flash[:error] = "Leave already created"
            redirect_to new_emergency_leaves_admin_leaves_path and return true
          end
        
          false
        end
        
        def validate_leave_limits(selected_user, leave_type)
          return false unless selected_user && leave_type
        
          start_date, end_date = determine_quarter_dates(selected_user, leave_type)
          if leave_type == 'annual'
            year = Date.today.year
            start_date = Date.new(year, 1, 1)
            end_date = Date.new(year, 12, 31)
            check_leaves = Leave.where(leave_type: leave_type, user_id: selected_user, status: 1)
                              .where("start_date <= ? AND end_date >= ?", end_date, start_date)
          else
            check_leaves = Leave.where(leave_type: leave_type, user_id: selected_user, status: 1)
                              .where("start_date <= ? AND end_date >= ?", end_date, start_date)
          end
          total_leave_days = check_leaves.inject(0) do |sum, leave|
            leave_days = (leave.end_date - leave.start_date).to_i + 1
            sum + leave_days
          end
        
          limit_reached = (leave_type == 'quarterly' && total_leave_days >= 3) ||
                          (leave_type == 'annual' && total_leave_days >= 8)
        
          if limit_reached
            flash[:error] = "Emergency leave cannot be marked. The selected employee has no unused leave available."
            redirect_to new_emergency_leaves_admin_leaves_path and return true
          end
        
          false
        end
        
        def determine_quarter_dates(selected_user, leave_type)
          return nil, nil unless selected_user
        
          selected_date = Date.parse(params[:selected_date]) rescue nil
          case selected_date.month
          when 1..3
            [Date.new(selected_date.year, 1, 1), Date.new(selected_date.year, 3, 31)]
          when 4..6
            [Date.new(selected_date.year, 4, 1), Date.new(selected_date.year, 6, 30)]
          when 7..9
            [Date.new(selected_date.year, 7, 1), Date.new(selected_date.year, 9, 30)]
          when 10..12
            [Date.new(selected_date.year, 10, 1), Date.new(selected_date.year, 12, 31)]
          end
        end

        def public_holiday_exists?(selected_date)
          PublicHoliday.where('? BETWEEN start_date AND end_date', selected_date).exists?
        end

        def invalid_leave_request?(selected_date, leave_type, one_year_anniversary, quarterly_restricted)
          if selected_date.saturday? || selected_date.sunday?
            redirect_to get_emergency_leaves_admin_leaves_path, flash: { error: "You cannot add emergency leave on weekends." }
            return true
          end
        
          if public_holiday_exists?(selected_date)
            redirect_to get_emergency_leaves_admin_leaves_path, flash: { error: "You cannot add emergency leave on Public Holiday." }
            return true
          end
        
          if Date.today < one_year_anniversary && leave_type == 'annual'
            redirect_to get_emergency_leaves_admin_leaves_path, flash: { error: "Leave requests are available only after 3 months of service." }
            return true
          end
        
          if Date.today < quarterly_restricted && leave_type == 'quarterly'
            redirect_to get_emergency_leaves_admin_leaves_path, flash: { error: "You must complete 3 months of employment before requesting quarterly leave." }
            return true
          end
        
          false
        end

        def exceeds_leave_limit?(leave_type, leave_days, year_start, year_end, user_id, annual_leaves, unused_quarterly_leaves, allotted_annual_leaves)
          leave_limits = {
            'annual' => ENV["ANNUAL_LEAVE"].to_i,
            'quarterly' => ENV["QUATER_LEAVE"].to_i
          }
          return false unless leave_limits.keys.include?(leave_type)   
          leaves_count = Leave.where(
            user_id: user_id,
            leave_type: leave_type,
            status: 1,
            start_date: year_start..year_end
          ).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }        
          leaves_count + leave_days > (unused_quarterly_leaves + allotted_annual_leaves.to_i) - annual_leaves
        end

        def determine_leave_period(leave_type, leave)
          if leave_type == 'annual' || leave_type == 'wedding'
            current_year_start = Date.new(Date.today.year, 1, 1)
            current_year_end = Date.new(Date.today.year, 12, 31)
          elsif leave_type == 'quarterly'
            leave_start = leave.start_date
            case leave_start.month
            when 1..3
              current_year_start = Date.new(leave_start.year, 1, 1)
              current_year_end = Date.new(leave_start.year, 3, 31)
            when 4..6
              current_year_start = Date.new(leave_start.year, 4, 1)
              current_year_end = Date.new(leave_start.year, 6, 30)
            when 7..9
              current_year_start = Date.new(leave_start.year, 7, 1)
              current_year_end = Date.new(leave_start.year, 9, 30)
            when 10..12
              current_year_start = Date.new(leave_start.year, 10, 1)
              current_year_end = Date.new(leave_start.year, 12, 31)
            end
          end
          [current_year_start, current_year_end]
        end
        
end