class JobApplication < ApplicationRecord
  before_validation :sanitize_phone_number
  # Validations
  validates :name, :email, :qualification, :cnic, :current_experience, :contact_number, :current_salary, :expected_salary, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :cnic, presence: true, format: { with: /\A\d{13}\z/, message: "must be exactly 13 digits" }
  validates :contact_number, format: { with: /\A\+\d{1,4}\d{6,14}\z/, message: "Enter a valid phone number." }
  # Associations
  belongs_to :job_post
  has_many :interviews, dependent: :destroy
  # Enums
  enum interview_status: { pending: 0, scheduled: 1, hired: 2, rejected: 3 }

  # Scopes
  scope :available, -> { where(interview_status: [:pending, :scheduled]) }

  private

  def sanitize_phone_number
    self.contact_number = contact_number.gsub(/[\s\-\(\)]/, '') if contact_number.present?
  end
end

