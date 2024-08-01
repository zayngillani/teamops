# app/mailers/job_application_mailer.rb
class JobApplicationMailer < ApplicationMailer
  default from: 'mailer@techcreatix.com'

  def confirmation_email(job_application, job_title)
    @job_application = job_application
    @job_title = job_title
    attachments.inline['email_logo.svg'] = File.read(Rails.root.join('app/assets/images/email_logo.svg'))
    attachments.inline['thank_you.svg'] = File.read(Rails.root.join('app/assets/images/thank_you.svg'))
    attachments.inline['linkedin.svg'] = File.read(Rails.root.join('app/assets/images/linkedin.svg'))
    attachments.inline['twitter.svg'] = File.read(Rails.root.join('app/assets/images/twitter.svg'))
    attachments.inline['facebook.svg'] = File.read(Rails.root.join('app/assets/images/facebook.svg'))
    attachments.inline['instagram.svg'] = File.read(Rails.root.join('app/assets/images/instagram.svg'))
    mail(
      to: @job_application.email,
      subject: 'Confirmation of Job Application'
    )
  end

  def notification_email(job_application, job_title)
    @job_application = job_application
    @job_title = job_title
    @hr_email = 'zayngillani017@gmail.com'
    mail(
      to: @hr_email,
      subject: "Job Application Notification - #{@job_application.name}"
    )
  end

  def interview_scheduled(interview)
    @interview = interview
    @job_application = @interview.job_application
    @job_post = @job_application.job_post
    @company_name = 'Techcreatix'
    @interview_date = @interview.interview_date.strftime("%A %B %d, %Y")
    @interview_time = @interview.interview_time.strftime("%I:%M %p")
    attachments.inline['email_logo.png'] = File.read(Rails.root.join('app/assets/images/email_logo.png'))
    attachments.inline['schedule_email.svg'] = File.read(Rails.root.join('app/assets/images/schedule_email.svg'))
    attachments.inline['linkedin.svg'] = File.read(Rails.root.join('app/assets/images/linkedin.svg'))
    attachments.inline['twitter.svg'] = File.read(Rails.root.join('app/assets/images/twitter.svg'))
    attachments.inline['facebook.svg'] = File.read(Rails.root.join('app/assets/images/facebook.svg'))
    attachments.inline['instagram.svg'] = File.read(Rails.root.join('app/assets/images/instagram.svg'))
    mail to: @job_application.email, subject: 'Interview Scheduled'
  end
end
