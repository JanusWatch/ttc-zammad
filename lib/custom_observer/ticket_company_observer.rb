module CustomObserver
  class TicketCompanyObserver < ActiveRecord::Observer
    observe :ticket

    def after_create(ticket)
      set_company_from_customer(ticket)
    end

    def after_update(ticket)
      # Also update if customer changes
      set_company_from_customer(ticket) if ticket.saved_change_to_customer_id?
    end

    private

    def set_company_from_customer(ticket)
      return if ticket.customer_id.blank?

      customer = User.find_by(id: ticket.customer_id)
      return if customer&.organization_id.blank?

      organization = Organization.find_by(id: customer.organization_id)
      return if organization.blank?

      # Update without triggering callbacks (avoids infinite loop)
      ticket.update_column(:company, organization.name)
    end
  end
end 
