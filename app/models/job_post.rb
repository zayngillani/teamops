class JobPost < ApplicationRecord
  # Validations
  validates :title, presence: true
  validates :details, presence: true
  validates :requirements_and_qualification, presence: true
  # Associations
  has_many :job_applications, dependent: :destroy
  # Enums
  enum job_status: [:active, :non_active]
end
