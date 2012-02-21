require 'spec_helper'

describe "protocol_roles/index.html.erb" do
  before(:each) do
    assign(:protocol_roles, [
      stub_model(ProtocolRole,
        :user_id => 1,
        :protocol_id => 1,
        :role => "Role"
      ),
      stub_model(ProtocolRole,
        :user_id => 1,
        :protocol_id => 1,
        :role => "Role"
      )
    ])
  end

  it "renders a list of protocol_roles" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Role".to_s, :count => 2
  end
end
