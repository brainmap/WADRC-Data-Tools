require 'spec_helper'

describe "blooddraws/index.html.erb" do
  before(:each) do
    assign(:blooddraws, [
      stub_model(Blooddraw,
        :appointment_id => 1
      ),
      stub_model(Blooddraw,
        :appointment_id => 1
      )
    ])
  end

  it "renders a list of blooddraws" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
