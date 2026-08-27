class App.SignatureHelper

  # Look up the active signature for a ticket. The ticket's organization
  # signature takes priority over the group signature (mirrors the desktop
  # form updater, FormUpdater::Concerns::PreparesTicketSignature), falling back
  # to the group signature when the organization has none.
  # Returns { signature, organization } or { signature, group } or null.
  @findForTicket: (ticket, groupId) ->
    @findForOrganization(ticket) or @findForGroup(groupId)

  # Look up active signature for a ticket's organization.
  # Returns { signature, organization } or null.
  @findForOrganization: (ticket) ->
    return null unless ticket?.organization_id
    return null unless App.Organization.exists(ticket.organization_id)
    organization = App.Organization.find(ticket.organization_id)
    return null unless organization?.signature_id
    return null unless App.Signature.exists(organization.signature_id)
    signature = App.Signature.find(organization.signature_id)
    return null unless signature?.active && signature.body
    { signature, organization }

  # Look up active signature for a group. Returns { signature, group } or null.
  @findForGroup: (groupId) ->
    return null unless groupId
    group = App.Group.find(groupId)
    return null unless group?.signature_id
    signature = App.Signature.find(group.signature_id)
    return null unless signature?.active && signature.body
    { signature, group }

  # Render signature body with tag replacement. Ticket data is passed in, session/config are resolved internally.
  @render: (signatureBody, ticket) ->
    App.Utils.replaceTags(signatureBody, { user: App.Session.get(), ticket: ticket, config: App.Config.all() })

  # Build signature DOM element with data attributes (returns jQuery object).
  @buildElement: (signatureId, renderedBody) ->
    el = $("<div data-signature=\"true\" data-signature-id=\"#{signatureId}\">#{renderedBody}</div>")
    App.Utils.htmlStrip(el)
    el

  # Remove top-level signatures from body (preserves signatures inside blockquotes).
  @removeTopLevel: (body) ->
    body.find('[data-signature=true]').not('blockquote [data-signature=true]').remove()

  # Append signature at the bottom of body, with spacing if needed.
  @appendToBottom: (body, signatureEl) ->
    if !App.Utils.htmlLastLineEmpty(body)
      body.append('<br><br>')
    body.append(signatureEl)
