class SlackService
     def initialize(user, message, time)
          binding.pry
          @user = user
          @time = time
          @message = message
          @channel = ENV["SLACK_CHANNEL"]
          @client = Slack::Web::Client.new
     end

     def send_message
          binding.pry
         @client.chat_postMessage(channel: @channel,text: "#{@message} by <@#{@user.slack_member_id}> at #{@time.in_time_zone("Asia/Karachi").strftime("%I:%M %p")}")
     end
end