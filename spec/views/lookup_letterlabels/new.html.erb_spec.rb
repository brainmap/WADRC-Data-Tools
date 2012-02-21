require 'spec_helper'

describe "lookup_letterlabels/new.html.erb" do
  before(:each) do
    assign(:lookup_letterlabel, stub_model(LookupLetterlabel,
      :description => "MyString",
      :protocol_id => 1,
      :doccategory => 1
    ).as_new_record)
  end

  it "renders new lookup_letterlabel form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_letterlabels_path, :method => "post" do
      assert_select "input#lookup_letterlabel_description", :name => "lookup_letterlabel[description]"
      assert_select "input#lookup_letterlabel_protocol_id", :name => "lookup_letterlabel[protocol_id]"
      assert_select "input#lookup_letterlabel_doccategory", :name => "lookup_letterlabel[doccategory]"
    end
  end
end
