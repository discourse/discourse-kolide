# frozen_string_literal: true

require 'rails_helper'
require_relative '../spec_helper'

describe PrettyText do
  include_context "with kolide spec helper"

  it "can properly decorate policies" do
    raw = "[kolide-assign user=123 device=456]"
    expect(PrettyText.cook raw).to eq('<p><a class="kolide-assign" href="#" data-user="123" data-device="456">assign</a></p>')
  end
end
