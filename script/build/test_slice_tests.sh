#!/bin/bash
LEVEL=$1

if [ "$LEVEL" == '1' ]; then
  echo "slicing level 1"

  # no ticket action
  # test/browser/aab_basic_urls_test.rb
  # test/browser/aab_unit_test.rb
  # test/browser/aac_basic_richtext_test.rb
  # test/browser/abb_one_group_test.rb
  rm test/browser/admin_channel_email_test.rb
  rm test/browser/admin_overview_test.rb
  # test/browser/agent_navigation_and_title_test.rb
  rm test/browser/agent_organization_profile_test.rb
  rm test/browser/agent_ticket_*.rb
  # test/browser/agent_user_manage_test.rb
  rm test/browser/agent_user_profile_test.rb
  # test/browser/auth_test.rb
  rm test/browser/chat_test.rb
  rm test/browser/customer_ticket_create_test.rb
  rm test/browser/first_steps_test.rb
  # test/browser/form_test.rb
  rm test/browser/keyboard_shortcuts_test.rb
  # test/browser/maintenance_app_version_test.rb
  # test/browser/maintenance_message_test.rb
  rm test/browser/prefereces_test.rb
  rm test/browser/setting_test.rb
  # test/browser/signup_password_change_and_reset_test.rb
  # test/browser/swich_to_user_test.rb
  # test/browser/taskbar_session_test.rb
  # test/browser/taskbar_task_test.rb
  # test/browser/translation_test.rb

elif [ "$LEVEL" == '2' ]; then
  echo "slicing level 2"

  # only ticket action 1/2
  rm test/browser/aab_basic_urls_test.rb
  rm test/browser/aab_unit_test.rb
  rm test/browser/aac_basic_richtext_test.rb
  # test/browser/abb_one_group_test.rb
  rm test/browser/admin_channel_email_test.rb
  rm test/browser/admin_overview_test.rb
  rm test/browser/agent_navigation_and_title_test.rb
  rm test/browser/agent_organization_profile_test.rb
  # test/browser/agent_ticket_actions_*.rb
  rm test/browser/agent_ticket_overview_*.rb
  rm test/browser/agent_user_*.rb
  rm test/browser/auth_test.rb
  rm test/browser/chat_test.rb
  rm test/browser/customer_ticket_create_test.rb
  rm test/browser/first_steps_test.rb
  rm test/browser/form_test.rb
  rm test/browser/keyboard_shortcuts_test.rb
  rm test/browser/maintenance_*.rb
  rm test/browser/manage_test.rb
  rm test/browser/prefereces_test.rb
  rm test/browser/setting_test.rb
  rm test/browser/signup_password_change_and_reset_test.rb
  rm test/browser/switch_to_user_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/translation_test.rb

elif [ "$LEVEL" == '3' ]; then
  echo "slicing level 3"

  # only ticket action 2/2
  rm test/browser/aab_basic_urls_test.rb
  rm test/browser/aab_unit_test.rb
  rm test/browser/aac_basic_richtext_test.rb
  # test/browser/abb_one_group_test.rb
  rm test/browser/admin_channel_email_test.rb
  rm test/browser/admin_overview_test.rb
  rm test/browser/agent_navigation_and_title_test.rb
  rm test/browser/agent_organization_profile_test.rb
  rm test/browser/agent_ticket_actions_*.rb
  # test/browser/agent_ticket_overview_*.rb
  rm test/browser/agent_user_*.rb
  rm test/browser/auth_test.rb
  # test/browser/chat_test.rb
  # test/browser/customer_ticket_create_test.rb
  rm test/browser/first_steps_test.rb
  rm test/browser/form_test.rb
  rm test/browser/keyboard_shortcuts_test.rb
  rm test/browser/maintenance_*.rb
  rm test/browser/manage_test.rb
  rm test/browser/prefereces_test.rb
  rm test/browser/setting_test.rb
  rm test/browser/signup_password_change_and_reset_test.rb
  rm test/browser/switch_to_user_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/translation_test.rb

elif [ "$LEVEL" == '4' ]; then
  echo "slicing level 4"

  # only profile action & admin
  rm test/browser/aab_basic_urls_test.rb
  rm test/browser/aab_unit_test.rb
  rm test/browser/aac_basic_richtext_test.rb
  # test/browser/abb_one_group_test.rb
  # test/browser/admin_channel_email_test.rb
  # test/browser/admin_overview_test.rb
  rm test/browser/agent_navigation_and_title_test.rb
  # test/browser/agent_organization_profile_test.rb
  rm test/browser/agent_ticket_*.rb
  rm test/browser/agent_user_manage_test.rb
  # test/browser/agent_user_profile_test.rb
  rm test/browser/auth_test.rb
  rm test/browser/chat_test.rb
  rm test/browser/customer_ticket_create_test.rb
  # test/browser/first_steps_test.rb
  rm test/browser/form_test.rb
  # test/browser/keyboard_shortcuts_test.rb
  rm test/browser/maintenance_*.rb
  rm test/browser/manage_test.rb
  # test/browser/preferences_test.rb
  # test/browser/setting_test.rb
  rm test/browser/signup_password_change_and_reset_test.rb
  rm test/browser/switch_to_user_test.rb
  rm test/browser/taskbar_session_test.rb
  rm test/browser/taskbar_task_test.rb
  rm test/browser/translation_test.rb

else
  echo "ERROR: Invalid level $LEVEL - 1, 2 or 3 is available"
  exit 1
fi

