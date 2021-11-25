# frozen_string_literal: true

module ::Jobs
  class SyncKolide < ::Jobs::Scheduled
    every 15.minutes

    def execute(args)
      return unless SiteSetting.kolide_enabled && SiteSetting.kolide_api_key

      ::Kolide.sync!
    end
  end
end
