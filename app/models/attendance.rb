class Attendance < ApplicationRecord
     belongs_to :user
     has_many :breaks, dependent: :destroy


end
