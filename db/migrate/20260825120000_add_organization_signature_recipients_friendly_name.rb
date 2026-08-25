# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddOrganizationSignatureRecipientsFriendlyName < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :signature, :string, limit: 30_000, null: true
    add_column :organizations, :recommended_recipients, :string, limit: 8000, null: true
    add_column :organizations, :friendly_name, :string, limit: 150, null: true

    # The identify_organization postmaster pre-filter was removed: Zammad's
    # check_default_organization derives the ticket organization from the
    # sender (customer) and overrides any mailbox-stamped value, so the filter
    # was redundant. Drop its setting on existing installs (fresh installs no
    # longer seed it).
    Setting.find_by(name: '6006_postmaster_filter_identify_organization')&.destroy

    # return if it's a new setup - the seeds already cover the attributes below
    return if !Setting.exists?(name: 'system_init_done')

    # ObjectManager::Attribute validates created_by/updated_by; a migration has
    # no request/user context, so set one explicitly.
    UserInfo.current_user_id = 1

    add_organization_attribute('signature', 'Signature', 'richtext', 30_000, 1500)
    add_organization_attribute('recommended_recipients', 'Recommended Recipients', 'richtext', 8000, 1510)
    add_organization_attribute('friendly_name', 'Friendly Name', 'input', 150, 1520)
  end

  private

  def add_organization_attribute(name, display, data_type, maxlength, position)
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Organization',
      name:        name,
      display:     display,
      data_type:   data_type,
      data_option: {
        default:    '',
        null:       true,
        maxlength:  maxlength,
        do_not_log: true,
      },
      editable:    false,
      internal:    true,
      active:      true,
      screens:     {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit:   {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    position,
    )
  end
end
