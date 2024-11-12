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
      render json: { error: 'Request timestamp is too old' }, status: :unauthorized and return
    end
  
    # Generate the signature
    sig_basestring = "v0:#{slack_timestamp}:#{request.raw_post}"
    my_signature = 'v0=' + OpenSSL::HMAC.hexdigest('sha256', ENV['SLACK_SIGNING_SECRET'], sig_basestring)
  
    # Compare Slack's signature with yours in a secure way
    unless Rack::Utils.secure_compare(my_signature, slack_signature)
      render json: { error: 'Invalid Slack signature' }, status: :unauthorized and return
    end
  
    # Define allowed Slack user IDs
    allowed_user_ids = ENV['SLACK_USERS'].split(',')
    # Check if the user triggering the action is allowed
    slack_user_id = payload['user']['id']
    unless allowed_user_ids.include?(slack_user_id)
      render json: { error: 'Forbidden: User not allowed' }, status: :forbidden and return
    end
  
    action_type, leave = value.split('_', 2)

    @leave = Leave.find_by(id: leave)
    
    if @leave.status == "pending"
      if action_type == "approve"
        @leave.update!(status: 1)
        status_message = "approved"
      elsif action_type == "reject"
        @leave.update!(status: 2)
        status_message = "rejected"
      end
    else
      render json: { error: 'Leave status not editable' }, status: :forbidden and return
    end
  
    # Respond with success
    render json: { status: "#{@leave.user.slack_member_id}'s Leave has been #{status_message} by Admin" }, status: :ok
  end
  
end