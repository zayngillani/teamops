class SystemAlert
  def initialize(message)
    @message = message
    @channel = ENV["TEST_CHANNEL"]
    @client = Slack::Web::Client.new
  end

  def send_message
    @client.chat_postMessage(
      channel: @channel,
      text: @message
    )
  end
end