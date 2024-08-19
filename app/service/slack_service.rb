class SlackService
     def initialize(user, message, time, channel = nil, report = nil)
          @user = user
          @time = time
          @message = message
          @report = report
          @channel = channel || determine_channel
          @client = Slack::Web::Client.new
     end
     
     def determine_channel
       if @user.email.ends_with?("@techcreatix.com")
          ENV["SLACK_CHANNEL"]
       elsif @time.is_a?(Time)
          ENV["TEST_CHANNEL"]
       end
     end
   
     def send_message
          @client.chat_postMessage(
               channel: @channel,
               text: "<@#{@user.slack_member_id}> #{@message} at #{@time.in_time_zone('Asia/Karachi').strftime('%b %d, %I:%M%p %Z')}"
          )
     end
     
     def send_leave
          @request_user = User.find_by(id: @time.user_id)
          @client.chat_postMessage(
               channel: ENV["LEAVE_CHANNEL"],
               text: "<@#{@request_user.slack_member_id}> #{@message} #{@user.name} from #{@time.start_date.strftime('%d/%B/%Y')} to #{@time.end_date.strftime('%d/%B/%Y')}"
          )
     end
     
     def send_report
          report_lines = @report.split("\n").map { |line| "• #{line.strip}" }.join("\n")
          @client.chat_postMessage(
            channel: @channel,
            text: "<@#{@user.slack_member_id}> #{@message} at #{@time.in_time_zone('Asia/Karachi').strftime('%b %d, %I:%M%p %Z')}\n\n" \
                  "Here is the report of <@#{@user.slack_member_id}> at #{@time.in_time_zone('Asia/Karachi').strftime('%b %d, %I:%M%p %Z')}:\n\n" \
                  "#{report_lines}"
          )
     end
   end
   