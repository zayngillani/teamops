class Admin::UsersController < ApplicationController

     def index
      session = User.where(role: "user", deleted: false).order(created_at: :desc)
      @session = session.paginate(page: params[:page], per_page: 10)

     end
     def new
       @user = User.new
     end
   
     def create
       @existing_user = User.where(email: params[:user][:email])
      if @existing_user.present?
        flash[:error] = "Email Already Exist"
        redirect_to root_path
      else
        @user = User.new(user_params)
        @user.ip_address = "#{request.headers['X-Forwarded-For']&.split(',')&.last&.strip} || " + "#{request.ip} || " + "#{request.remote_ip}"
        @user.role = "user"
        @user.password =  params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
        if @user.save
          flash[:success] = "User created successfully"
          redirect_to root_path
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
      start_date = Date.new(@year, @month, 1)
      end_date = start_date.end_of_month
      @user_sessions = @user.attendances.where(check_in_time: start_date.beginning_of_day..end_date.end_of_day).order(created_at: :asc)
      date_range = (start_date.to_date..end_date.to_date).to_a
      date_range.reject! { |date| date.saturday? || date.sunday? }
      present_dates = @user_sessions.pluck(:check_in_time).map(&:to_date)
      @leaves = date_range.count { |date| !present_dates.include?(date) && date < Date.today }
      if @user_sessions.present?
        total_hrs = 0
        @user_sessions.each do |attendance|
          total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
        end
        @total_hours = total_hrs
        respond_to do |format|
            format.html
            format.pdf { render pdf: "#{@user.name}", layout: false } # Specify view and disable layout
        end
      else
        flash[:error] = "Attendance Not Present"
        redirect_to root_path
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
      session = User.where(role: "user", deleted: false).order(created_at: :desc)
      @session = session.paginate(page: params[:page], per_page: 10)
    end

    def user_detail
      @user = User.find_by(id: params[:id])
      start_date = Date.current.beginning_of_month
      end_date = Date.current.end_of_month
      @user_sessions = @user.attendances.where(check_in_time: start_date.beginning_of_day..end_date.end_of_day).order(created_at: :asc)
      date_range = (start_date.to_date..end_date.to_date).to_a
      date_range.reject! { |date| date.saturday? || date.sunday? }
      present_dates = @user_sessions.pluck(:check_in_time).map(&:to_date)
      @leaves = date_range.count { |date| !present_dates.include?(date) && date < Date.today }
      if @user_sessions.present?
        total_hrs = 0
        @user_sessions.each do |attendance|
          total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
        end
        @total_hours = total_hrs
      else
        flash[:error] = "Attendance Not Present"
        redirect_to root_path
      end
    end

    def user_leave
      @month = params[:month].to_i
      @year = params[:year].to_i
      @users = User.where(role: "user", deleted: false).order(created_at: :desc)
      start_date = Date.new(@year, @month, 1)
      end_date = start_date.end_of_month
      @user_leaves = {}
      @users.each do |user|
        date_range = (start_date..end_date).to_a
        date_range.reject! { |date| date.saturday? || date.sunday? }
        present_dates = user.attendances.pluck(:check_in_time).map(&:to_date)
        leaves = date_range.count { |date| !present_dates.include?(date) && date < Date.today }
        @user_leaves[user.name] = leaves
    end
    end
    def leave_report
      @month = params[:month].to_i
      @year = params[:year].to_i
      @users = User.where(role: "user", deleted: false)
      start_date = Date.new(@year, @month, 1)
      end_date = start_date.end_of_month
      
      @user_leaves = {}
      @users.each do |user|
        date_range = (start_date..end_date).to_a
        date_range.reject! { |date| date.saturday? || date.sunday? }
        present_dates = user.attendances.pluck(:check_in_time).map(&:to_date)
        leaves = date_range.count { |date| !present_dates.include?(date) && date < Date.today }
        @user_leaves[user.name] = leaves
      end
      if @user_leaves.present?
        respond_to do |format|
          format.html
          format.pdf { render pdf: "leavesreport", layout: false } # Specify view and disable layout
        end
      else
        flash[:error] = "Attendance Not Present"
        redirect_to root_path
      end
    end

    def monthly_report
      @users = User.where(role: "user", deleted: false).order(created_at: :desc)
      @month = params[:month].to_i
      @year = params[:year].to_i
      start_date = Date.new(@year, @month, 1)
      end_date = start_date.end_of_month
    
      @total_hours = {} # Hash to store total hours for each user
    
      @users.each do |user|
        user_sessions = user.attendances.where(check_in_time: start_date.beginning_of_day..end_date.end_of_day).order(created_at: :asc)
        total_hrs = 0
    
        user_sessions.each do |attendance|
          total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
        end
    
        # Store total hours for each user in the hash
        @total_hours[user.id] = total_hrs
      end
    end

    def monthly_users_list
      @users = User.where(role: "user", deleted: false).order(created_at: :desc)
      @month = params[:month].to_i
      @year = params[:year].to_i
      start_date = Date.new(@year, @month, 1)
      end_date = start_date.end_of_month
    
      @total_hours = {} # Hash to store total hours for each user
    
      @users.each do |user|
        user_sessions = user.attendances.where(check_in_time: start_date.beginning_of_day..end_date.end_of_day).order(created_at: :asc)
        total_hrs = 0
    
        user_sessions.each do |attendance|
          total_hrs += attendance.total_hours.to_i unless attendance.total_hours.nil?
        end
    
        # Store total hours for each user in the hash
        @total_hours[user.id] = total_hrs
      end
      if @total_hours.present?
        respond_to do |format|
          format.html
          format.pdf { render pdf: "leavesreport", layout: false } # Specify view and disable layout
        end
      else
        flash[:error] = "Attendance Not Present"
        redirect_to root_path
      end
    end
    
    

    
     private
   
     def user_params
       params.require(:user).permit(:email, :name, :slack_member_id, :supervisor)
     end
   end
   