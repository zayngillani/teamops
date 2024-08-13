class PublicLink < ApplicationRecord
  belongs_to :interview

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create

  def expired?
    Time.current > expires_at
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(10)
  end
end
