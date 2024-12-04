class ContactDetailSlackService
  def initialize(contact_detail, identifier)
    @identifier = identifier
    @contact_detail = contact_detail
    @slack_client = Slack::Web::Client.new(token: ENV['SLACK_TX_ALERT_TOKEN'])
  end

  def send_notification
    message = build_message
    post_message(message)
  end

  private

  def build_message
    case @identifier
    when 'GetCallRequested'
      <<~MESSAGE
      *Get a Call Requested:*
      *Name:* #{@contact_detail.details['name']}
      *Contact Number:* #{@contact_detail.details['contact_no']}
    MESSAGE
    when 'portfolioRequested'
      <<~MESSAGE
      *Portfolio Requested:*
      *Name:* #{@contact_detail.details['name']}
      *Email:* #{@contact_detail.details['email']}
      *Portfolio Title:* #{@contact_detail.details['title']}
    MESSAGE
    when 'contactDetail'
      <<~MESSAGE
        *New Contact Detail Created:*
        *Name:* #{@contact_detail.details['name']}
        *Email:* #{@contact_detail.details['email']}
        *Contact Number:* #{@contact_detail.details['contact_no']}
        *Project Details:* #{@contact_detail.details['project_details']}
      MESSAGE
    end
  end

  def post_message(message)
    if Rails.env.production?
      @slack_client.chat_postMessage(channel: ENV['CONTACT_DETAILS_CHANNEL'], text: message)
    else
      @slack_client.chat_postMessage(channel: ENV['TEST_CHANNEL'], text: message)
    end
  end
end