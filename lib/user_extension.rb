# frozen_string_literal: true

module Kolide::UserExtension
  def self.prepended(base)
    base.has_many :kolide_devices, class_name: "::Kolide::Device"

    base.class_eval do
      def self.find_by_kolide_json(data)
        return if data.blank?

        custom_field =
          UserCustomField.find_or_initialize_by(name: "kolide_person_id", value: data["id"])
        return custom_field.user unless custom_field.new_record?

        email = data["email"]
        user = User.find_by_email(email)

        if user.blank?
          Rails.logger.warn("Unable find the Discourse user for email address '#{email}'")
          return
        end

        custom_field.user_id = user.id
        custom_field.save!

        user
      end

      def kolide_id
        custom_fields["kolide_person_id"]
      end
    end
  end
end
