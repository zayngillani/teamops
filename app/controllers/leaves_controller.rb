class LeavesController < ApplicationController
     def index
          @p_leaves = Leave.where(status: 0)
          if @p_leaves.present? && @p_leaves.any?
            @pending_leaves = User.where(id: @p_leaves.pluck(:user_id))
          else
            @pending_leaves = []
          end
        
          @a_leaves = Leave.where(status: 1)
          if @a_leaves.present? && @a_leaves.any?
            @accepted_leaves = User.where(id: @a_leaves.pluck(:user_id))
          else
            @accepted_leaves = []
          end
        
          @r_leaves = Leave.where(status: 2)
          if @r_leaves.present? && @r_leaves.any?
            @rejected_leaves = User.where(id: @r_leaves.pluck(:user_id))
          else
            @rejected_leaves = []
          end
        end
        
     
     def new
          @leaves = current_user.leaves
     end
     
     def create
          start_date = params[:user][:start_date]
          end_date = params[:user][:end_date]
          leave_start = Date.parse(params[:user][:start_date])
          leave_end = Date.parse(params[:user][:end_date])
          current_month_start = Date.today.beginning_of_month
          current_month_end = Date.today.end_of_month
          next_month_start = current_month_start.next_month
          next_month_end = current_month_end.next_month
          leaves_current_month = Leave.where(user_id: current_user.id)
          .where("start_date >= ? AND start_date <= ?", current_month_start, current_month_end)
          .count
          leaves_next_month = Leave.where(user_id: current_user.id)
          .where("start_date >= ? AND start_date <= ?", next_month_start, next_month_end)
          .count
          holiday = PublicHoliday.find_by(start_date: start_date..end_date)
          if start_date.present?
            if leave_start > next_month_end
              redirect_to root_path, flash: { error: "You cannot request leaves for future months" }
              return
            elsif leave_start.between?(current_month_start, current_month_end)
              if leaves_current_month >= 2
                redirect_to root_path, flash: { error: "You can only request two leaves in the current month" }
                return
              end
            elsif leave_start.between?(next_month_start, next_month_end)
              if leaves_next_month >= 2
                redirect_to root_path, flash: { error: "You can only request two leaves in the next month" }
                return
              end
            end
          end
          if leave_start.saturday? || leave_start.sunday? || leave_end.saturday? || leave_end.sunday?
            redirect_to root_path, flash: { error: "You can't request leave for weekends (Saturday or Sunday)." }
            return
          end
          if Leave.exists?(user_id: current_user.id, status: [0, 1, 2], start_date: params[:user][:start_date]..params[:user][:end_date])
            redirect_to root_path, flash: { error: "Leave Already Submitted" }
            return
          end
          if leave_start == Date.today
            redirect_to root_path, flash: { error: "You cannot request leave for today. Please select a future date." }
            return
          end
          if params[:user][:start_date] > params[:user][:end_date]
            redirect_to root_path, flash: { error: "End date must be greater than or equal to start date" }
            return
          end
          if holiday.present?
            redirect_to root_path, flash: { error: "You can't request for Leave on Public Holiday" }
            return
          end
          if Leave.exists?(user_id: current_user.id, status: [0, 1, 2], start_date: start_date..end_date)
            redirect_to root_path, flash: { error: "Leave Already Submitted" }
            return
          end
          @leave = Leave.new
          @leave.start_date = params[:user][:start_date]
          @leave.end_date = params[:user][:end_date]
          @leave.user_id = current_user.id
          @leave.reason = params[:user][:reason]
          if @leave.save
            # SlackService.new(current_user, "Request leave from", @leave).request_leave
            redirect_to root_path, notice: 'Leave request submitted.'
          else
            render :new
          end
     end
     
     def show
          if params[:accept].present?
          @leaves = Leave.where(status: 1, user_id: params[:id])
          elsif params[:reject].present?
          @leaves = Leave.where(status: 2, user_id: params[:id])
          else
          @leaves = Leave.where(status: 0, user_id: params[:id])
          end
     end

     def approve
          leave = Leave.find_by(id: params[:id])
          if leave.update(status: 1)
            SlackService.new(current_user, "Leave approved by", leave).send_leave
               flash[:success] = "Leave Approved"
               redirect_to leaves_path
          else
               flash[:error] = "Leave not found"
          end
     end

     def reject
          leave = Leave.find_by(id: params[:id])
          if leave.update(status: 2)
            # SlackService.new(current_user, "Leave rejected by", leave).send_leave
               flash[:success] = "Leave Rejected"
               redirect_to leaves_path
          else
               flash[:error] = "Leave not found"
          end
     end

     private

     def leave_params
          params.require(:leaves).permit(:start_date, :end_date, :reason)
     end
end