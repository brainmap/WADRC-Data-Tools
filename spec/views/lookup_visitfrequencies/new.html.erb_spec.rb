require 'spec_helper'

describe "lookup_visitfrequencies/new.html.erb" do
  before(:each) do
    assign(:lookup_visitfrequency, stub_model(LookupVisitfrequency,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_visitfrequency form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_visitfrequencies_path, :method => "post" do
      assert_select "input#lookup_visitfrequency_description", :name => "lookup_visitfrequency[description]"
    end
  end
end
