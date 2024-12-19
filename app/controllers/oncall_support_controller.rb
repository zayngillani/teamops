class OncallSupportController < ApplicationController
     include OncallHelper

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
          @oncall = Oncall.new(
            start_date: params[:start_date],
            end_date: params[:end_date],
            reason: params[:reason],
            user_id: current_user.id,
            status: "pending"
          )
          start_date = Date.parse(params[:start_date])
          end_date = Date.parse(params[:end_date])
          unless valid_date_range?(start_date, end_date)
            redirect_to show_oncalls_path, flash: { error: "End date must be greater than or equal to start date" }
            return
          end
          if oncall_exists?(current_user.id, start_date, end_date)
            redirect_to show_oncalls_path, flash: { error: "Oncall Already Submitted" }
            return
          end
          leaves = approved_leaves(current_user.id, start_date, end_date)
          holidays = public_holidays(start_date, end_date)
      
          (start_date..end_date).each do |date|
            unless valid_oncall_date?(date, holidays, leaves)
              redirect_to show_oncalls_path, flash: { error: "On-call requests are only allowed on holidays, weekends, or during approved leave." }
              return
            end
          end
          if @oncall.save
            flash[:success] = 'On Call Support Request Submitted'
          else
            flash[:error] = "Reason cannot be empty or contain only spaces."
          end
          redirect_to show_oncalls_path
     end
end