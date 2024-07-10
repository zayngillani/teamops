class JobPost < ApplicationRecord
  has_many :job_applications, dependent: :destroy

  enum job_status: [:active, :non_active]
end
