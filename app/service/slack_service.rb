class SlackService
     def initialize(user, message, time)
          @user = user
          @time = time
          @message = message
          if @user.email.ends_with?("@gmail.com")
               @channel = ENV["TEST_CHANNEL"]
          elsif @time.is_a?(Time)
               @channel = ENV["SLACK_CHANNEL"]
          elsif
               @channel = ENV["LEAVE_CHANNEL"]
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
          text: "<@#{@request_user.slack_member_id}> #{@message} #{@user.name} from #{@time.start_date.strftime("%d/%B/%Y")} to #{@time.end_date.strftime("%d/%B/%Y")}"
       )
     end
end