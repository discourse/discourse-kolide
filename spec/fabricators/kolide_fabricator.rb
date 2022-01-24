# frozen_string_literal: true

Fabricator(:kolide_device, from: "::Kolide::Device") do
  user
  uid { sequence(:uid) }
  name "My Mac"
  hardware_model "Macbook"
  ip_address "127.0.0.1"
end

Fabricator(:kolide_check, from: "::Kolide::Check") do
  uid { sequence(:uid) }
  name "Ensure Supported OS Version"
  display_name "Windows Update - Ensure Supported OS Version"
  description "Obsolete Windows versions no longer receive important security updates and patches, and could leave you vulnerable to exploits."
  failing_device_count 1
  delay 0
end

Fabricator(:kolide_issue, from: "::Kolide::Issue") do
  device { Fabricate(:kolide_device) }
  check { Fabricate(:kolide_check) }
  uid { sequence(:uid) }
  title "Screen Lock Disabled"
  data '{ "user": "deviceuser" }'
  reported_at 1.days.ago
  resolved_at nil
end
