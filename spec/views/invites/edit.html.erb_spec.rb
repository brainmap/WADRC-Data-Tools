require 'spec_helper'

describe "invites/edit.html.erb" do
  before(:each) do
    @invite = assign(:invite, stub_model(Invite))
  end

  it "renders the edit invite form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => invite_path(@invite), :method => "post" do
    end
  end
end
