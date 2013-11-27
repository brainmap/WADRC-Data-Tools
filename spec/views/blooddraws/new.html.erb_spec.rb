require 'spec_helper'

describe "blooddraws/new.html.erb" do
  before(:each) do
    assign(:blooddraw, stub_model(Blooddraw,
      :appointment_id => 1
    ).as_new_record)
  end

  it "renders new blooddraw form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => blooddraws_path, :method => "post" do
      assert_select "input#blooddraw_appointment_id", :name => "blooddraw[appointment_id]"
    end
  end
end
