require 'spec_helper'

describe "lookup_visitfrequencies/edit.html.erb" do
  before(:each) do
    @lookup_visitfrequency = assign(:lookup_visitfrequency, stub_model(LookupVisitfrequency,
      :description => "MyString"
    ))
  end

  it "renders the edit lookup_visitfrequency form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_visitfrequency_path(@lookup_visitfrequency), :method => "post" do
      assert_select "input#lookup_visitfrequency_description", :name => "lookup_visitfrequency[description]"
    end
  end
end
