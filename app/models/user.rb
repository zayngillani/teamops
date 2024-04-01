class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable

  has_many :attendances 
  enum role: [:user, :admin]
  enum status: [:active , :pending]

  def password_expired?
    password_changed_at.nil? || password_changed_at.present? && password_changed_at < Devise.expire_password_after.ago
  end

  def active_for_authentication?
    super && status != 'pending'
  end

  def inactive_message
    status == 'pending' ? :pending : super
  end
  
end
