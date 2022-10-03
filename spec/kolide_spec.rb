# frozen_string_literal: true

require 'rails_helper'
require_relative 'spec_helper'

describe Kolide do
  include_context "with kolide spec helper"

  let(:user) { Fabricate(:user) }
  let(:device) { Fabricate(:kolide_device, user: user, user_id: user.id, uid: 12345) }
  let(:issue) { Fabricate(:kolide_issue, device: device) }

  def stub_api(type)
    content = { status: 200, headers: { "Content-Type" => "application/json" } }
    url = "#{::Kolide::Api::BASE_URL}#{type == :issues ? "issues/open" : type}?per_page=500"
    content = content.merge(body: get_kolide_response("#{type}.json"))
    stub_request(:get, url).to_return(content)
  end

  before do
    user.custom_fields["kolide_person_id"] = "23456"
    user.save_custom_fields

    stub_api(:devices)
    stub_api(:checks)
    stub_api(:issues)
  end

  describe "sync!" do
    it "updates alert post after issues resolved" do
      issue
      ::Kolide::UserAlert.new(user)

      post = Topic.private_messages_for_user(user).last.first_post
      expect(post.raw).to include("[^#{issue.id}]: user: deviceuser")

      ::Kolide.sync!

      expect(issue.reload.resolved).to be_truthy
      expect(post.reload.raw).not_to include("[^#{issue.id}]: user: deviceuser")
    end
  end
end
