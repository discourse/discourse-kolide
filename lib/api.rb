# frozen_string_literal: true

module ::Kolide
  class InvalidApiResponse < ::StandardError
  end

  class Api
    attr_reader :client

    def initialize
      @client =
        Faraday.new(
          url: Api::BASE_URL,
          headers: {
            "Authorization" => "Bearer #{SiteSetting.kolide_api_key}",
            "Accept" => "application/json",
            "Content-Type" => "application/json",
          },
        )
    end

    BASE_URL = "https://k2.kolide.com/api/v0/"

    def parse(response)
      case response.status
      when 200
        return JSON.parse response.body
      else
        e = ::Kolide::InvalidApiResponse.new(response.body.presence || "")
        e.set_backtrace(caller)
        Discourse.warn_exception(
          e,
          message: I18n.t("kolide.error.invalid_response"),
          env: {
            api_uri: response.env.url.to_s,
          },
        )
      end

      { error: I18n.t("kolide.error.invalid_response") }
    end

    %i[get put post].each do |request_method|
      define_method(request_method) do |uri, params = {}|
        if request_method == :get
          params[:per_page] ||= 100
        else
          params = params.to_json
        end

        response = client.public_send(request_method, uri, params)
        parse(response)
      end

      def get_all(uri, params = {})
        result = { data: [] }

        loop do
          response = get(uri, params)
          return response if response[:error].present?

          result[:data] += response["data"]
          params[:cursor] = response["pagination"]["next_cursor"]
          break if params[:cursor].blank?
        end

        result
      end
    end
  end
end
