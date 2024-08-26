class Admin::DailyReportsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:index] # Use with caution

  def index
    @users = User.active.where(role: 'user').ransack(name_cont: params[:q]).result.order(name: :asc).paginate(page: params[:page], per_page: 10)
    respond_to do |format|
      format.html
      format.js { render partial: 'search', locals: { users: @users } }
    end
  end

   def show
     @month = params[:month].present? ? params[:month].to_i : Date.current.month
     @year = params[:year].present? ? params[:year].to_i : Date.current.year
     @start_date = Date.new(@year, @month, 1)
     @end_date = @start_date.end_of_month
     @user = User.find_by(id: params[:id])
     @sessions = Attendance.where(user_id: @user.id, check_in_time: @start_date.beginning_of_day..@end_date.end_of_day).order(created_at: :asc).paginate(page: params[:page], per_page: 10)
   end

   def report
     @daily_report = Attendance.find_by(id: params[:format])
   end

   def search
     @q = User.ransack(params[:q])
     @users = @q.result(distinct: true)
 
     respond_to do |format|
       format.js { render partial: 'daily_reports/search', locals: { users: @users } }
       format.html { redirect_to admin_daily_reports_path(q: params[:q]) } # Fallback if JS is disabled
     end
   end
end