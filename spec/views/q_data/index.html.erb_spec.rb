require 'spec_helper'

describe "q_data/index.html.erb" do
  before(:each) do
    assign(:q_data, [
      stub_model(QDatum,
        :q_data_form_id => 1,
        :question_id => 1,
        :value_link => 1,
        :value_1 => "Value 1",
        :value_2 => "Value 2",
        :value_3 => "Value 3"
      ),
      stub_model(QDatum,
        :q_data_form_id => 1,
        :question_id => 1,
        :value_link => 1,
        :value_1 => "Value 1",
        :value_2 => "Value 2",
        :value_3 => "Value 3"
      )
    ])
  end

  it "renders a list of q_data" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value 3".to_s, :count => 2
  end
end
