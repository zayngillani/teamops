class JobApplicationSlackService
  def initialize(job_application, job_title, resume_file)
    @job_title = job_title
    @job_application = job_application
    @resume_file = resume_file
    @slack_client = Slack::Web::Client.new(token: ENV['SLACK_TX_ALERT_TOKEN'])
  end

  def notify_submission
    file_url = "http/test/test-resume.pdf"
    message = build_message(file_url)
    post_message(message)
  end

  private

  def build_message(file_url)
    <<~MESSAGE
      #{@job_application.name} applied for this job post #{@job_title}. Please find below resume of the candidate
      - **Resume**: [View Resume](#{file_url})
    MESSAGE
  end

  def build_message(file_url)
    <<~MESSAGE
      *New job application submitted*
      ```
      Job Title: #{@job_title}
      Name: #{@job_application.name}
      Email: #{@job_application.email}
      Qualification: #{@job_application.qualification}
      Current Experience: #{@job_application.current_experience}
      Contact Number: #{@job_application.contact_number}
      Current Salary: #{@job_application.current_salary}
      Expected Salary: #{@job_application.expected_salary}
      ```
      *Resume*: <#{file_url}|View Resume>
    MESSAGE
  end  

  def post_message(message)
    @slack_client.chat_postMessage(channel: ENV['TEST_CHANNEL'], text: message)
  end

  # def upload_resume_file
  #   response = @slack_client.files_upload(
  #     channels: ENV['TEST_CHANNEL'],
  #     as_user: true,
  #     file: Faraday::UploadIO.new(@resume_file.path, 'application/pdf'),
  #     title: "#{@job_application.name}'s Resume",
  #     filename: @resume_file.original_filename
  #   )
  #   response.file.permalink
  # end
end
