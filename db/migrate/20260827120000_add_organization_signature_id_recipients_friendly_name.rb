# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddOrganizationSignatureIdRecipientsFriendlyName < ActiveRecord::Migration[7.2]
  def up
    # Consolidated replacement for the earlier
    # 20260825120000 (richtext signature + recipients + friendly_name) and
    # 20260826120000 (convert signature -> signature_id reference) migrations.
    # Those two were removed so that installs which never ran them (e.g. prod)
    # go straight to the final state without transiently creating the old
    # richtext `signature` field. This migration is idempotent so it also
    # no-ops on installs that already reached the final state via the old pair.

    # Belt-and-suspenders: drop the old free-text `signature` field if some
    # earlier build created it. Use delete_all, not destroy_all: the attribute
    # is internal: true and ObjectManager::Attribute blocks destroying internal
    # attributes via `before_destroy :internal_attribute_indelible` (throw
    # :abort), which would silently leave it orphaned. delete_all issues a raw
    # DELETE that skips the guard.
    ObjectManager::Attribute.where(
      object_lookup_id: ObjectLookup.by_name('Organization'),
      name:             'signature'
    ).delete_all
    remove_column :organizations, :signature if column_exists?(:organizations, :signature)

    add_column :organizations, :recommended_recipients, :string, limit: 8000, null: true if !column_exists?(:organizations, :recommended_recipients)
    add_column :organizations, :friendly_name, :string, limit: 150, null: true if !column_exists?(:organizations, :friendly_name)
    add_reference :organizations, :signature, type: :integer, foreign_key: true, null: true if !column_exists?(:organizations, :signature_id)

    Organization.reset_column_information

    # The identify_organization postmaster pre-filter was removed: Zammad's
    # check_default_organization derives the ticket organization from the
    # sender (customer) and overrides any mailbox-stamped value, so the filter
    # was redundant. Drop its setting (created by
    # 20260820120000_add_email_address_to_organizations) on existing installs;
    # fresh installs no longer seed it.
    Setting.find_by(name: '6006_postmaster_filter_identify_organization')&.destroy

    # return if it's a new setup - the seeds already cover the attributes below
    return if !Setting.exists?(name: 'system_init_done')

    # ObjectManager::Attribute validates created_by/updated_by; a migration has
    # no request/user context, so set one explicitly.
    UserInfo.current_user_id = 1

    # The organization signature is chosen from existing (preconfigured)
    # Signatures - mirroring Group's belongs_to :signature - and overrides the
    # group signature the same way the organization mailbox overrides the group
    # email address.
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

    add_organization_attribute('recommended_recipients', 'Recommended Recipients', 'richtext', 8000, 1510)
    add_organization_attribute('friendly_name', 'Friendly Name', 'input', 150, 1520)
  end

  private

  def add_organization_attribute(name, display, data_type, maxlength, position)
    data_option = {
      default:    '',
      null:       true,
      maxlength:  maxlength,
      do_not_log: true,
    }
    # 'input' attributes require an explicit HTML input type; richtext does not.
    data_option[:type] = 'text' if data_type == 'input'

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Organization',
      name:        name,
      display:     display,
      data_type:   data_type,
      data_option: data_option,
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
