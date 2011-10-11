require 'spec_helper'

describe "invites/index.html.erb" do
  before(:each) do
    assign(:invites, [
      stub_model(Invite),
      stub_model(Invite)
    ])
  end

  it "renders a list of invites" do
    render
  end
end
