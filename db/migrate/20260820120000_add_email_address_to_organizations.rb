# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddEmailAddressToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_reference :organizations, :email_address, type: :integer, foreign_key: true, null: true

    # return if it's a new setup - the seeds already cover this case
    return if !Setting.exists?(name: 'system_init_done')

    # ObjectManager::Attribute validates created_by/updated_by; a migration has
    # no request/user context, so set one explicitly (mirrors Zammad's own
    # migrations, e.g. 20230801092655_issue_4543_organization_vip.rb).
    UserInfo.current_user_id = 1

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Organization',
      name:        'email_address_id',
      display:     'Mailbox',
      data_type:   'select',
      data_option: {
        default:    '',
        multiple:   false,
        null:       true,
        relation:   'EmailAddress',
        nulloption: true,
        do_not_log: true,
        note:       'The mailbox from which follow-up emails on any ticket of this organization are sent, and to which incoming emails are assigned as tickets of this organization.',
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
      position:    1460,
    )

    Setting.create_if_not_exists(
      name:        '6006_postmaster_filter_identify_organization',
      title:       'Defines postmaster filter.',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to identify ticket organization based on the mailbox the email arrived on.',
      options:     {},
      state:       'Channel::Filter::IdentifyOrganization',
      frontend:    false
    )
  end
end
