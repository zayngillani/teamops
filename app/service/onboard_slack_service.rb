class OnboardSlackService
  def initialize(message , email)
    @email = email
    @message = message
    @client = Slack::Web::Client.new(token: ENV['SLACK_TX_ALERT_TOKEN'])
  end

  def channel
    if Rails.env.production?
      ENV['CONTACT_DETAILS_CHANNEL']
    else
      ENV['TEST_CHANNEL']
    end
  end

  def send_onboard_alert
    @client.chat_postMessage(
               channel: channel,
               text: "<@#{ENV["HR_ID"]}> #{@message} #{@email}"
          )
  end
end