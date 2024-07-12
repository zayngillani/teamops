class JobApplicationSlackService
  def initialize(job_application, job_title)
    @job_title = job_title
    @job_application = job_application
    @slack_client = Slack::Web::Client.new(token: ENV['SLACK_TX_ALERT_TOKEN'])
  end

  def notify_submission
    message = build_message
    post_message(message)
  end

  private

  def build_message
    <<~MESSAGE
      *#{@job_application.name}* has applied for the *#{@job_title}* position today, #{Time.now.strftime("%d/%B/%Y")}.
      *Contact details:*
      Email: #{@job_application.email}
    MESSAGE
  end  

  def post_message(message)
    @slack_client.chat_postMessage(channel: ENV['TEST_CHANNEL'], text: message)
  end
end
