class ContactDetail < ApplicationRecord
  validates :details, presence: true
  before_save :extract_email_and_contact

  scope :search_by_contact_type, -> (contact_type) { 
    where("contact_type ILIKE ?", "%#{contact_type}%") if contact_type.present? 
  }

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

  private
  
  def extract_email_and_contact
    self.email = details['email']
    self.contact_no = details['contact_no']
  end
end
