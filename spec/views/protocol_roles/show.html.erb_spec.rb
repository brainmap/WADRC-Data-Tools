require 'spec_helper'

describe "protocol_roles/show.html.erb" do
  before(:each) do
    @protocol_role = assign(:protocol_role, stub_model(ProtocolRole,
      :user_id => 1,
      :protocol_id => 1,
      :role => "Role"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Role/)
  end
end
