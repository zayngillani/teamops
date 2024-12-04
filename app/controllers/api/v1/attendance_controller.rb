class Api::V1::AttendanceController < ApplicationController
  before_action :authenticate_user_from_token!

  def checkin_or_checkout
    action_type = params[:action_type]

    case action_type
    when 'checkin'
      handle_checkin
    when 'checkout'
      handle_checkout
    else
      render json: { error: 'Invalid action type' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def break_action
    action = params[:action_type]
    @session = Attendance.find_by(id: params[:id])
    if action == 'break_in'
      handle_break_in(@session)
    elsif action == 'break_out'
      handle_break_out(@session)
    else
      render json: { error: 'Invalid action type' }, status: :unprocessable_entity
    end
  end

  private

  def authenticate_user_from_token!
    token = request.headers['Authorization']&.split(' ')&.last || params[:access_token]
    @current_user = User.find_by(authentication_token: token)
    unless @current_user
      render json: { error: 'Invalid or missing token' }, status: :unauthorized
    end
  end

  def handle_checkin
    session = Attendance.find_today_checkin(@current_user)
    if session.present?
      render json: { error: 'You have already checked in today.' }, status: :unprocessable_entity
    else
      attendance = @current_user.attendances.create!(check_in_time: Time.now.utc)
      render json: { message: 'Check-in successfully', attendance: attendance }, status: :ok
    end
  end

  def handle_checkout
    session = Attendance.find_today_checkin(@current_user)
    if session.present?
      if session.check_out_time.nil?
        if params[:report].present?
          session.update!(check_out_time: Time.now.utc)
          total_duration_seconds = session.check_out_time - session.check_in_time
          total_break_time = session.calculate_total_break_time
          total_duration_seconds -= total_break_time
          session.update!(total_hours: total_duration_seconds, report: params[:report])
          render json: { message: 'Check-out successfully', attendance: session }, status: :ok
        else
          render json: { error: 'Daily Report is Missing.' }, status: :unprocessable_entity
        end
      else
        render json: { error: 'You have already checked out today.' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'No active session to check out.' }, status: :unprocessable_entity
    end
  end

  def handle_break_in(session)
    if session && session.check_out_time.nil?
      last_break = session.breaks.last
      if last_break.nil? || (last_break.break_in_time.present? && last_break.break_out_time.present?)
        session.breaks.create!(break_in_time: Time.now.utc)
        SlackService.new(current_user, "Break In", Time.now.utc).send_message
        render json: { message: "On a break" }, status: :ok
      else
        render json: { error: "You are already on a break" }, status: :unprocessable_entity
      end
    else
      render json: { error: "No active session or session already checked out" }, status: :unprocessable_entity
    end
  end

  def handle_break_out(session)
    if session && session.check_out_time.nil?
      last_break = session.breaks.last
      if last_break&.break_in_time.present? && last_break.break_out_time.nil?
        last_break.update!(break_out_time: Time.now.utc)
        total_break_time = session.calculate_total_break_time
        session.update!(total_break: total_break_time)
        SlackService.new(current_user, "Break Out", Time.now.utc).send_message
        render json: { message: "Back from break", total_break_time: total_break_time }, status: :ok
      else
        render json: { error: "You are not on a break" }, status: :unprocessable_entity
      end
    else
      render json: { error: "No active session or session already checked out" }, status: :unprocessable_entity
    end
  end
end
