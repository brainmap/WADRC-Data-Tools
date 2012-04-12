require 'spec_helper'

describe "q_data/show.html.erb" do
  before(:each) do
    @q_datum = assign(:q_datum, stub_model(QDatum,
      :q_data_form_id => 1,
      :question_id => 1,
      :value_link => 1,
      :value_1 => "Value 1",
      :value_2 => "Value 2",
      :value_3 => "Value 3"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value 3/)
  end
end
