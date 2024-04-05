class LeavesController < ApplicationController
     def index
          @pending = Leave.where(status: 0)
     end

     def new
     end
     
     def create
          @leave = Leave.new
          @leave.start_date = params[:user][:start_date]
          @leave.end_date = params[:user][:end_date]
          @leave.user_id = current_user.id
          @leave.reason = params[:user][:reason]
          if @leave.save!
               redirect_to root_path, notice: 'Leave request submitted.'
          else
               render :new
          end
     end

     private

     def leave_params
          params.require(:leaves).permit(:start_date, :end_date, :reason)
     end
end