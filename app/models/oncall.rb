class Oncall < ApplicationRecord
     belongs_to :user
     enum status: [:pending, :approved, :rejected]
end