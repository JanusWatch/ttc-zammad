# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::IdentifyOrganization, type: :channel_filter do
  let(:organization)  { create(:organization, email_address:) }
  let(:email_address) { create(:email_address, channel:) }
  let(:channel)       { create(:channel) }

  context 'when organization id is already present on the mail' do
    let(:mail_hash) { { 'x-zammad-ticket-organization_id': organization.id } }

    it 'does not do anything' do
      filter(mail_hash, channel:)

      expect(mail_hash).to eq('x-zammad-ticket-organization_id': organization.id)
    end
  end

  context 'when the mail belongs to an existing ticket' do
    let(:other_organization) { create(:organization) }
    let(:ticket)             { create(:ticket, organization: other_organization) }
    let(:mail_hash)          { { 'x-zammad-ticket-id': ticket.id } }

    it 'does not override the existing ticket organization' do
      filter(mail_hash, channel:)

      expect(mail_hash).not_to include(:'x-zammad-ticket-organization_id')
    end
  end

  context 'when the channel is linked to an organization mailbox' do
    let(:mail_hash) { {} }

    before { organization }

    it 'sets the organization by the channel mailbox' do
      filter(mail_hash, channel:)

      expect(mail_hash).to include('x-zammad-ticket-organization_id': organization.id)
    end
  end

  context 'when the channel has an email address but it is not linked to any organization' do
    let(:mail_hash) { {} }

    before { email_address }

    it 'does not set an organization' do
      filter(mail_hash, channel:)

      expect(mail_hash).not_to include(:'x-zammad-ticket-organization_id')
    end
  end

  context 'when the channel has no email address at all' do
    let(:mail_hash) { {} }

    it 'does not set an organization' do
      filter(mail_hash, channel:)

      expect(mail_hash).not_to include(:'x-zammad-ticket-organization_id')
    end
  end
end
