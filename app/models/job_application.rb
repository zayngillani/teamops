class JobApplication < ApplicationRecord
  validates :name, :email, :qualification, :cnic, :current_experience, :contact_number, :current_salary, :expected_salary, :resume_link, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :cnic, format: { with: /\A\d{13}\z/, message: "must be 13 digits" }
  validates :contact_number, format: { with: /\A\d{10,15}\z/, message: "must be between 10 and 15 digits" }
end
