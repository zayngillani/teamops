class JobApplicationSlackService
  def initialize(job_application)
    @job_application = job_application
    @slack_client = Slack::Web::Client.new
  end

  def notify_submission
    message = build_message
    @slack_client.chat_postMessage(channel: ENV['TEST_CHANNEL'], text: message)
  end

  private

  def build_message
    <<~MESSAGE
      New job application submitted:
      Name: #{@job_application.name}
      Email: #{@job_application.email}
      Qualification: #{@job_application.qualification}
      Current Experience: #{@job_application.current_experience}
      Contact Number: #{@job_application.contact_number}
      Current Salary: #{@job_application.current_salary}
      Expected Salary: #{@job_application.expected_salary}
      Resume: #{@job_application.resume_link}
    MESSAGE
  end
end
