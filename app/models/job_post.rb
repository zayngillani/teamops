class JobPost < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  # Validations
  validates :title, presence: true
  validates :details, presence: true
  validates :requirements_and_qualification, presence: true
  # Associations
  has_many :job_applications, dependent: :destroy
  # Enums
  enum job_status: [:active, :non_active]
  # Scopes
  default_scope { where(deleted_at: nil) }
  scope :with_deleted, -> { unscope(where: :deleted_at) }

  # Check if the record is deleted
  def deleted?
    deleted_at.present?
  end

  # Soft delete the record
  def soft_delete
    update(deleted_at: Time.current)
  end

  # Restore the record
  def restore
    update(deleted_at: nil)
  end
end
