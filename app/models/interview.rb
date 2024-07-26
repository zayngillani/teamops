class Interview < ApplicationRecord
  belongs_to :job_application

  enum status: { active: 0, inactive: 1 }
  enum result: { pending: 0, completed: 1, cancelled: 2 }

  validates :interview_date, presence: true
  validates :interview_time, presence: true

  after_create :send_interview_email, :update_job_application_status

  private

  def send_interview_email
    JobApplicationMailer.interview_scheduled(self).deliver_now
  end

  def update_job_application_status
    job_application.update(interview_status: 1)
  end
end
