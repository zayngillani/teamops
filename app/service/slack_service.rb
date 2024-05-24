class SlackService
     def initialize(user, message, time)
          @user = user
          @time = time
          @message = message
          if @user.email.ends_with?("@gmail.com") || !@time.is_a?(Time)
               @channel = ENV["TEST_CHANNEL"]
          else
               @channel = ENV["SLACK_CHANNEL"]
          end
          @client = Slack::Web::Client.new
     end

     def send_message
          @client.chat_postMessage(channel: @channel,text: " <@#{@user.slack_member_id}> #{@message} at #{@time.in_time_zone('Asia/Karachi').strftime("%b %d, %I:%M%p %Z")}")
     end
     
     def send_leave
       @request_user = User.find_by(id: @time.user_id)
       @client.chat_postMessage(channel: @channel,
          channel: @channel,
          text: "<@#{@request_user.slack_member_id}> #{@message} #{@user.name} from #{@time.start_date.strftime("%d/%B")} to #{@time.end_date.strftime("%d/%B")}"
       )
     end
end