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
         @client.chat_postMessage(channel: @channel,text: " <@#{@user.slack_member_id}> #{@message} at #{@time.in_time_zone('Asia/Karachi').strftime("%b %d, %I:%M%p %Z")}")
     end
end