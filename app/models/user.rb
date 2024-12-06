class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable

  has_many :attendances
  has_many :leaves

  enum role: [:user, :admin]
  enum status: [:active , :pending]
  enum user_type: { dev: 0, qa: 1, designer: 2, devops: 3 }

  validates :email, presence: false
  validates :password, presence: false

  before_create :generate_authentication_token


  def generate_authentication_token
    loop do
      self.authentication_token = Devise.friendly_token
      break unless User.exists?(authentication_token: authentication_token)
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id name email role created_at updated_at]
  end

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
