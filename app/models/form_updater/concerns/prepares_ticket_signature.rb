# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::PreparesTicketSignature
  extend ActiveSupport::Concern

  def resolve
    maybe_prepare_ticket_signature if agent?

    super
  end

  private

  def maybe_prepare_ticket_signature
    # Only prepare signature on initial load, or when group or article type has changed.
    return if !meta[:initial] && meta.dig(:changed_field, :name) != 'group_id' && meta.dig(:changed_field, :name) != 'articleSenderType'

    result_initialize_field('body')

    signature = effective_signature
    if signature.nil?
      result['body'][:signature] = nil
      return
    end

    # Fake a ticket object for create screen if a group is present (#4448).
    ticket = object || Struct.new(:group).new(group)

    result['body'][:signature] = {
      internalId:   signature[:internal_id],
      renderedBody: NotificationFactory::Renderer.new(
        objects:  { user: current_user, ticket: },
        template: signature[:template],
        escape:   false
      ).render(debug_errors: false),
    }
  end

  # The ticket organization's Signature takes priority over the Group's for
  # outgoing replies, falling back to the group signature when the organization
  # has none. Returns a hash of { internal_id:, template: } or nil.
  def effective_signature
    signature = organization_signature || group_signature
    return nil if signature.nil?

    { internal_id: signature.id, template: signature.body_with_urls }
  end

  # Only available for an existing ticket (reply); on the create screen the
  # organization isn't established yet, so we fall back to the group signature.
  def organization_signature
    return nil if object&.organization&.signature_id.nil?

    @organization_signature ||= Signature.find(object.organization.signature_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def group_signature
    return nil if group.nil? || group.signature_id.nil?

    @group_signature ||= Signature.find(group.signature_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def group
    # Check first in the result, then in the data.
    #   It could happen the group value is coming from a dirty field in the taskbar.
    @group ||= Group.find(result.dig('group_id', :value) || data['group_id'])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def agent?
    current_user.permissions?('ticket.agent')
  end
end
