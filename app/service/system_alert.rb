class SystemAlert
  def initialize(message)
    @message = message
    @channel = ENV["SERVER_ALERTS"]
    @client = Slack::Web::Client.new
  end

  def send_message
    @client.chat_postMessage(
      channel: @channel,
      text: @message
    )
  end
end