class OncallSupportController < ApplicationController
     def show_oncalls
          @month = params[:month].present? ? params[:month].to_i : Date.today.month
          @year = params[:year].present? ? params[:year].to_i : Date.today.year
          @start_date = Date.new(@year, @month, 1)
          @end_date = @start_date.end_of_month
          current_month_start = @start_date.beginning_of_month
          current_month_end = @end_date.end_of_month
          request_status = params[:request_status].present? ? params[:request_status].to_i : nil
          @oncalls = Oncall.where("start_date <= ? AND end_date >= ? AND user_id = ?", current_month_end, current_month_start, current_user.id)
          if request_status
               @oncalls = @oncalls.where(request_status: request_status)
             end
          @oncalls = @oncalls.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
     end

     def create_oncall
          @oncall = Oncall.new
          @oncall.start_date = params[:start_date]
          @oncall.end_date = params[:end_date]
          @oncall.reason = params[:reason]
          @oncall.user_id = current_user.id
          if params[:start_date] > params[:end_date]
               redirect_to show_oncalls_path, flash: { error: "End date must be greater than or equal to start date" }
               return
          end
          if Oncall.exists?(user_id: current_user.id, request_status: [0, 1, 2], start_date: ..params[:start_date], end_date: params[:end_date]..)
               redirect_to show_oncalls_path, flash: { error: "Oncall Already Submitted" }
               return
          end
          approved_leaves = Leave.where(user_id: current_user.id, status: 'approved')
               .where("start_date <= ? AND end_date >= ?", params[:end_date], params[:start_date])
          public_holidays = PublicHoliday.where("start_date <= ? AND end_date >= ?", params[:end_date], params[:start_date])
          (Date.parse(params[:start_date])..Date.parse(params[:end_date])).each do |date|
          is_weekend = date.saturday? || date.sunday?
          is_public_holiday = public_holidays.any? { |holiday| date.between?(holiday.start_date, holiday.end_date) }
          is_approved_leave = approved_leaves.any? { |leave| date.between?(leave.start_date, leave.end_date) }
            unless is_weekend || is_public_holiday || is_approved_leave
              redirect_to show_oncalls_path, flash: { error: "On-call requests can only be created on weekends, approved leaves, or public holidays." }
              return
            end
          end
          if @oncall.save
            flash[:success] = 'On Call Support Request Submitted'
            redirect_to show_oncalls_path
          else
            flash[:error] = "Reason cannot be empty or contain only spaces."
            redirect_to show_oncalls_path
          end
     end
end