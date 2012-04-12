require 'spec_helper'

describe "q_data_forms/index.html.erb" do
  before(:each) do
    assign(:q_data_forms, [
      stub_model(QDataForm,
        :questionform_id => 1,
        :participant_id => 1,
        :visit_id => 1,
        :appointment_id => 1,
        :protocol_id => 1,
        :enrollment_id => 1
      ),
      stub_model(QDataForm,
        :questionform_id => 1,
        :participant_id => 1,
        :visit_id => 1,
        :appointment_id => 1,
        :protocol_id => 1,
        :enrollment_id => 1
      )
    ])
  end

  it "renders a list of q_data_forms" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
