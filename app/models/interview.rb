class Interview < ApplicationRecord
  belongs_to :job_application

  enum status: { active: 0, inactive: 1 }
  enum result: { pending: 0, completed: 1, cancelled: 2 }

  validates :interview_date, presence: true
  validates :interview_time, presence: true
  validate :interview_date_cannot_be_weekend

  after_create :send_interview_email, :update_job_application_status

  def interview_date_cannot_be_weekend
    if interview_date.present? && (interview_date.saturday? || interview_date.sunday?)
      errors.add(:interview_date, "cannot be a Saturday or Sunday")
    end
  end

  # def interview_time_cannot_be_in_past
  #   # TODO handle time zones correcly
  #   if interview_date.present? && interview_time.present?
      
  #     scheduled_time = DateTime.parse("#{interview_date} #{interview_time}")

  #     current_time = DateTime.now

  #     if  current_time > scheduled_time
  #       errors.add(:interview_time, "cannot be in the past")
  #     end
  #   end
  # end

  private

  def send_interview_email
    # JobApplicationMailer.interview_scheduled(self).deliver_now
  end

  def update_job_application_status
    job_application.update(interview_status: 1)
  end
end
