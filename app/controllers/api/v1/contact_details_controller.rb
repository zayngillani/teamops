module Api
  module V1
    class ContactDetailsController < Api::BaseController

      def create
        contact_detail = ContactDetail.new(contact_detail_params)
        identifier = params[:identifier]

        if contact_detail.save
          ContactDetailSlackService.new(contact_detail, identifier).send_notification
          message = identifier_message(identifier)
          render json: { status: 'success', message: message, data: contact_detail }, status: :created
        else
          render json: { status: 'error', message: 'Failed to create contact details', errors: contact_detail.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def contact_detail_params
        params.require(:contact_detail).permit(details: [:name, :email, :contact_no, :project_details, :title])
      end

      def identifier_message(identifier)
        case identifier
        when 'GetCallRequested', 'portfolioRequested'
          'We got your information, we will be in touch shortly.'
        else
          'Contact details created successfully'
        end
      end

    end
  end
end
