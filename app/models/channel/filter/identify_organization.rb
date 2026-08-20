# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::IdentifyOrganization
  def self.run(channel, mail, _transaction_params)
    return if mail[:'x-zammad-ticket-organization_id'].present?
    return if mail[:'x-zammad-ticket-id'].present? && Ticket.exists?(id: mail[:'x-zammad-ticket-id'])

    organization = pick_organization(channel)
    mail[:'x-zammad-ticket-organization_id'] = organization.id if organization
  end

  def self.pick_organization(channel)
    return if !channel[:id]

    email_address = EmailAddress.find_by(channel_id: channel[:id])
    return if !email_address

    Organization.find_by(email_address_id: email_address.id)
  end
end
