# frozen_string_literal: true

module ::Kolide

  class InvalidApiResponse < ::StandardError; end

  class Api

    BASE_URL = "https://k2.kolide.com/api/v0/"

    def get(uri)
      response = Faraday.new(
        url: Api::BASE_URL,
        headers: { 'Authorization' => "Bearer #{SiteSetting.kolide_api_key}" }
      ).get(uri)

      case response.status
      when 200
        return JSON.parse response.body
      else
        e = ::Kolide::InvalidApiResponse.new(response.body.presence || '')
        e.set_backtrace(caller)
        Discourse.warn_exception(e, message: I18n.t("kolide.error.invalid_response"), env: { api_uri: uri })
      end

      { error: I18n.t("kolide.error.invalid_response") }
    end

  end
end
