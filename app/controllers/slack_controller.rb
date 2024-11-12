class SlackController < ApplicationController
  skip_before_action :authenticate_user!, only: [:actions]
  skip_before_action :verify_authenticity_token, raise: false, only: [:actions]
  require 'openssl'


  def actions
    payload = JSON.parse(params[:payload]) rescue {}
    action = payload['actions'].first
    value = action['value']
    slack_signature = request.env['HTTP_X_SLACK_SIGNATURE']
    slack_timestamp = request.env['HTTP_X_SLACK_REQUEST_TIMESTAMP']
  
    if (Time.now.to_i - slack_timestamp.to_i).abs > 300
      render status: :unauthorized and return
    end
  
    sig_basestring = "v0:#{slack_timestamp}:#{request.raw_post}"
    my_signature = 'v0=' + OpenSSL::HMAC.hexdigest('sha256', ENV['SLACK_SIGNING_SECRET'], sig_basestring)
  
    unless Rack::Utils.secure_compare(my_signature, slack_signature)
      render status: :unauthorized and return
    end  
    allowed_user_ids = ENV['SLACK_USERS'].split(',')
    slack_user_id = payload['user']['id']
    unless allowed_user_ids.include?(slack_user_id)
      render status: :forbidden and return
    end
    action_type, leave = value.split('_', 2)
    if @leave.pending?
      @leave =  Leave.find_by(id: leave)
      if action_type == "approve"
        @leave.update!(status: 1)
      elsif action_type == "reject"
        @leave.update!(status: 2)
      end
    else
      render status: :forbidden and return
    end

    head :ok
  end
  
end
