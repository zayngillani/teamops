class IpManagement < ApplicationRecord
  enum status: [:enable , :disable]
  def soft_delete
    update(deleted_at: Time.current)
  end
end