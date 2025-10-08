# frozen_string_literal: true

module ::Kolide
  class IssuesController < ::ApplicationController
    requires_plugin Kolide::PLUGIN_NAME
    requires_login

    def recheck
      params.require(:issue_id)
      issue = Issue.find(params[:issue_id])

      response = Kolide.api.post("issues/#{issue.uid}/rechecks")

      if response[:error].present?
        render json: failed_json, status: :unprocessable_content
      else
        render json: success_json, status: :ok
      end
    end
  end
end
