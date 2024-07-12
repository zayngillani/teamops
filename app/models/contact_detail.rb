class ContactDetail < ApplicationRecord
  validates :details, presence: true

  def name
    details['name']
  end

  def email
    details['email']
  end

  def contact_no
    details['contact_no']
  end

  def project_details
    details['project_details']
  end
end
