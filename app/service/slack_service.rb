class SlackService
     def initialize(user, message, time)
          @user = user
          @time = time
          @message = message
          if @user.email.ends_with?("@gmail.com")
               @channel = ENV["TEST_CHANNEL"]
          else
               @channel = ENV["SLACK_CHANNEL"]
          end
          @client = Slack::Web::Client.new
     end

     def send_message
          begin
            @client.chat_postMessage(channel: @channel,text: " <@#{@user.slack_member_id}> #{@message} at #{@time.in_time_zone('Asia/Karachi').strftime("%b %d, %I:%M%p %Z")}")
          rescue Slack::Web::Api::Errors::TimeoutError => e
            Rails.logger.error "Slack API timeout: #{e.message}"
            false
          rescue Slack::Web::Api::Errors::SlackError => e
            Rails.logger.error "Slack API error: #{e.message}"
            false
          end
     end
end