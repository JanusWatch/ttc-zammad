# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChangeOrganizationSignatureToReference < ActiveRecord::Migration[7.2]
  def change
    # Replace the free-text `signature` richtext field with a `signature_id`
    # reference to a preconfigured Signature - mirroring Group's belongs_to
    # :signature and Organization's email_address_id. The org signature is now
    # chosen from existing signatures and overrides the group signature the same
    # way the organization mailbox overrides the group email address.

    # Drop the old richtext attribute + column. It only existed on environments
    # that ran the initial version and holds no production data.
    ObjectManager::Attribute.where(
      object_lookup_id: ObjectLookup.by_name('Organization'),
      name:             'signature'
    ).destroy_all
    remove_column :organizations, :signature, :string, limit: 30_000 if column_exists?(:organizations, :signature)
    Organization.reset_column_information

    add_reference :organizations, :signature, type: :integer, foreign_key: true, null: true
    Organization.reset_column_information

    # return if it's a new setup - the seeds already cover the attribute below
    return if !Setting.exists?(name: 'system_init_done')

    # ObjectManager::Attribute validates created_by/updated_by; a migration has
    # no request/user context, so set one explicitly.
    UserInfo.current_user_id = 1

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Organization',
      name:        'signature_id',
      display:     'Signature',
      data_type:   'select',
      data_option: {
        default:    '',
        multiple:   false,
        null:       true,
        relation:   'Signature',
        nulloption: true,
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
      position:    1500,
    )
  end
end
