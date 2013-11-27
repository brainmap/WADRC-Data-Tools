require 'spec_helper'

describe "blooddraws/edit.html.erb" do
  before(:each) do
    @blooddraw = assign(:blooddraw, stub_model(Blooddraw,
      :appointment_id => 1
    ))
  end

  it "renders the edit blooddraw form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => blooddraw_path(@blooddraw), :method => "post" do
      assert_select "input#blooddraw_appointment_id", :name => "blooddraw[appointment_id]"
    end
  end
end
