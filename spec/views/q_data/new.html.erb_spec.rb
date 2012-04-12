require 'spec_helper'

describe "q_data/new.html.erb" do
  before(:each) do
    assign(:q_datum, stub_model(QDatum,
      :q_data_form_id => 1,
      :question_id => 1,
      :value_link => 1,
      :value_1 => "MyString",
      :value_2 => "MyString",
      :value_3 => "MyString"
    ).as_new_record)
  end

  it "renders new q_datum form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => q_data_path, :method => "post" do
      assert_select "input#q_datum_q_data_form_id", :name => "q_datum[q_data_form_id]"
      assert_select "input#q_datum_question_id", :name => "q_datum[question_id]"
      assert_select "input#q_datum_value_link", :name => "q_datum[value_link]"
      assert_select "input#q_datum_value_1", :name => "q_datum[value_1]"
      assert_select "input#q_datum_value_2", :name => "q_datum[value_2]"
      assert_select "input#q_datum_value_3", :name => "q_datum[value_3]"
    end
  end
end
