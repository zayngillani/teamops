module Api
  module V1
    class ContactDetailsController < Api::BaseController

      def create
        contact_detail = ContactDetail.new(contact_detail_params)

        if contact_detail.save
          ContactDetailSlackService.new(contact_detail).send_notification
          render json: { status: 'success', message: 'Contact details created successfully', data: contact_detail }, status: :created
        else
          render json: { status: 'error', message: 'Failed to create contact details', errors: contact_detail.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def contact_detail_params
        params.require(:contact_detail).permit(details: [:name, :email, :contact_no, :project_details])
      end
    end
  end
end
