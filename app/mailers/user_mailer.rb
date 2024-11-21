class UserMailer < ApplicationMailer
  default from: 'mailer@techcreatix.com'

  def welcome_onboard_email(user)
    @user = user 
    @company_name = "TechCreatix"
    @hr_email = "mahnoor.techcreatix@gmail.com"
    @your_name = "Mahnoor Masood"
    @your_job_title = "HR Manager"
    @contact_info = "support@techcreatix.com"

    @profile_completion_url = "#{root_url}admin/users/#{@user.id}/complete_profile"

    mail(
      to: @user.email,
      subject: "Welcome to #{@company_name}!"
    )
  end
end