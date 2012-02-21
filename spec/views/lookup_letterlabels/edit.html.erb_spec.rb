require 'spec_helper'

describe "lookup_letterlabels/edit.html.erb" do
  before(:each) do
    @lookup_letterlabel = assign(:lookup_letterlabel, stub_model(LookupLetterlabel,
      :description => "MyString",
      :protocol_id => 1,
      :doccategory => 1
    ))
  end

  it "renders the edit lookup_letterlabel form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_letterlabel_path(@lookup_letterlabel), :method => "post" do
      assert_select "input#lookup_letterlabel_description", :name => "lookup_letterlabel[description]"
      assert_select "input#lookup_letterlabel_protocol_id", :name => "lookup_letterlabel[protocol_id]"
      assert_select "input#lookup_letterlabel_doccategory", :name => "lookup_letterlabel[doccategory]"
    end
  end
end
