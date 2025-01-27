class ContactDetail < ApplicationRecord
  validates :details, presence: true
  before_save :extract_email_and_contact

  scope :search, -> (query) {
  if query.present?
    where(
      "contact_type ILIKE :query OR details->>'name' ILIKE :query OR details->>'email' ILIKE :query OR details->>'contact_no' ILIKE :query",
      query: "%#{query}%"
    )
  end
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
