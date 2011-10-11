require 'spec_helper'

describe "invites/new.html.erb" do
  before(:each) do
    assign(:invite, stub_model(Invite).as_new_record)
  end

  it "renders new invite form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => invites_path, :method => "post" do
    end
  end
end
