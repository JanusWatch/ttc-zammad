Rails.application.config.after_initialize do
  Ticket.class_eval do
    after_create :set_company_from_customer
    after_update :set_company_from_customer, if: :saved_change_to_customer_id?

    private

    def set_company_from_customer
      return if customer_id.blank?
      return if customer&.organization_id.blank?

      organization = Organization.find_by(id: customer.organization_id)
      return if organization.blank?

      # Update without triggering callbacks (avoids infinite loop)
      update_column(:company, organization.name)
    end
  end
end
