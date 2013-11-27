require 'spec_helper'

describe "neuropsyches/edit.html.erb" do
  before(:each) do
    @neuropsych = assign(:neuropsych, stub_model(Neuropsych,
      :appointment_id => 1
    ))
  end

  it "renders the edit neuropsych form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => neuropsych_path(@neuropsych), :method => "post" do
      assert_select "input#neuropsych_appointment_id", :name => "neuropsych[appointment_id]"
    end
  end
end
