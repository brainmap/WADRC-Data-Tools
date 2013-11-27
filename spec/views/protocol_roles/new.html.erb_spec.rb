require 'spec_helper'

describe "protocol_roles/new.html.erb" do
  before(:each) do
    assign(:protocol_role, stub_model(ProtocolRole,
      :user_id => 1,
      :protocol_id => 1,
      :role => "MyString"
    ).as_new_record)
  end

  it "renders new protocol_role form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => protocol_roles_path, :method => "post" do
      assert_select "input#protocol_role_user_id", :name => "protocol_role[user_id]"
      assert_select "input#protocol_role_protocol_id", :name => "protocol_role[protocol_id]"
      assert_select "input#protocol_role_role", :name => "protocol_role[role]"
    end
  end
end
