class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable

  has_many :attendances
  has_many :leaves

  enum role: [:user, :admin]
  enum status: [:active , :pending]

  def password_expired?
    password_changed_at.nil? || password_changed_at.present? && password_changed_at < Devise.expire_password_after.ago
  end

  def active_for_authentication?
    super && status != 'pending' && deleted != true
  end

  def inactive_message
    status == 'pending' ? :pending : deleted == true ? :deleted:  super
  end
  
  def send_devise_notification(notification, *args)
    unless deleted? || status == "pending"
      super(notification, *args)
    end
  end
end
