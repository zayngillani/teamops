# app/mailers/job_application_mailer.rb
class JobApplicationMailer < ApplicationMailer
  default from: 'no-reply@yourcompany.com'

  def confirmation_email(job_application, job_title)
    @job_application = job_application
    @job_title = job_title
    mail(
      to: @job_application.email,
      subject: 'Confirmation of Job Application'
    )
  end

  def notification_email(job_application, job_title)
    @job_application = job_application
    @job_title = job_title
    @hr_email = 'hr@techcreatix.com'
    mail(
      to: @hr_email,
      subject: "Job Application Notification - #{@job_application.name}"
    )
  end
end
