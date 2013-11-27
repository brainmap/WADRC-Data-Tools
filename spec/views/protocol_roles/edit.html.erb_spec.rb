require 'spec_helper'

describe "protocol_roles/edit.html.erb" do
  before(:each) do
    @protocol_role = assign(:protocol_role, stub_model(ProtocolRole,
      :user_id => 1,
      :protocol_id => 1,
      :role => "MyString"
    ))
  end

  it "renders the edit protocol_role form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => protocol_role_path(@protocol_role), :method => "post" do
      assert_select "input#protocol_role_user_id", :name => "protocol_role[user_id]"
      assert_select "input#protocol_role_protocol_id", :name => "protocol_role[protocol_id]"
      assert_select "input#protocol_role_role", :name => "protocol_role[role]"
    end
  end
end
