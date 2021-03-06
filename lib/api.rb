# frozen_string_literal: true

module ::Kolide

  class InvalidApiResponse < ::StandardError; end

  class Api
    attr_reader :client

    def initialize
      @client = Faraday.new(
        url: Api::BASE_URL,
        headers: {
          'Authorization' => "Bearer #{SiteSetting.kolide_api_key}",
          'Accept' => "application/json",
          'Content-Type' => "application/json"
        }
      )
    end

    BASE_URL = "https://k2.kolide.com/api/v0/"

    def parse(response)
      case response.status
      when 200
        return JSON.parse response.body
      else
        e = ::Kolide::InvalidApiResponse.new(response.body.presence || '')
        e.set_backtrace(caller)
        Discourse.warn_exception(e, message: I18n.t("kolide.error.invalid_response"), env: { api_uri: response.env.url.to_s })
      end

      { error: I18n.t("kolide.error.invalid_response") }
    end

    def get(uri, params = {})
      params[:per_page] ||= 500
      parse(client.get(uri, params))
    end

    def put(uri, params)
      parse(client.put(uri, params.to_json))
    end
  end
end
