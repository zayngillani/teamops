class SlackController < ApplicationController
  skip_before_action :authenticate_user!, only: [:actions]
  skip_before_action :verify_authenticity_token, raise: false, only: [:actions]
  require 'openssl'

  def actions
    # Parse the payload
    payload = JSON.parse(params[:payload]) rescue {}
    action = payload['actions'].first
    value = action['value']

    # Retrieve the headers
    slack_signature = request.env['HTTP_X_SLACK_SIGNATURE']
    slack_timestamp = request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP']

    # Prevent replay attacks by ensuring the timestamp is recent (e.g., within 5 minutes)
    if (Time.now.to_i - slack_timestamp.to_i).abs > 300
      render status: :unauthorized and return
    end

    # Generate the signature
    sig_basestring = "v0:#{slack_timestamp}:#{request.raw_post}"
    my_signature = 'v0=' + OpenSSL::HMAC.hexdigest('sha256', ENV['SLACK_SIGNING_SECRET'], sig_basestring)

    # Compare Slack's signature with yours in a secure way
    unless Rack::Utils.secure_compare(my_signature, slack_signature)
      render status: :unauthorized and return
    end

    # Define allowed Slack user IDs
    allowed_user_ids = ENV['SLACK_USERS'].split(',')

    # Check if the user triggering the action is allowed
    slack_user_id = payload['user']['id']
    unless allowed_user_ids.include?(slack_user_id)
      render status: :forbidden and return
    end

    # Split the value and check if it's valid
    action_type, leave_id = value.split('_', 2)
    unless action_type && leave_id
      render status: :bad_request, json: { error: 'Invalid value format' } and return
    end

    # Find the leave
    @leave = Leave.find_by(id: leave_id)
    if @leave.nil?
      render status: :not_found, json: { error: 'Leave not found' } and return
    end

    # Check leave status and perform the action
    if @leave.status == 0
      if action_type == "approve"
        @leave.update!(status: 1)
      elsif action_type == "reject"
        @leave.update!(status: 2)
      else
        render status: :bad_request, json: { error: 'Invalid action type' } and return
      end
    else
      render status: :forbidden, json: { error: 'Leave request cannot be modified' } and return
    end

    head :ok
  end
end
