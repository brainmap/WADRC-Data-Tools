require 'spec_helper'

describe "invites/show.html.erb" do
  before(:each) do
    @invite = assign(:invite, stub_model(Invite))
  end

  it "renders attributes in <p>" do
    render
  end
end
