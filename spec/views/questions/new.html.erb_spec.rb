require 'spec_helper'

describe "questions/new.html.erb" do
  before(:each) do
    assign(:question, stub_model(Question,
      :heading_1 => "MyString",
      :phrase_a_1 => "MyString",
      :value_type_1 => "MyString",
      :ref_table_a_1 => "MyString",
      :ref_table_b_1 => "MyString",
      :phrase_b_1 => "MyString",
      :phrase_c_1 => "MyString",
      :required_y_n_1 => "MyString",
      :heading_2 => "MyString",
      :phrase_a_2 => "MyString",
      :value_type_2 => "MyString",
      :ref_table_a_2 => "MyString",
      :ref_table_b_2 => "MyString",
      :phrase_b_2 => "MyString",
      :phrase_c_2 => "MyString",
      :required_y_n_2 => "MyString",
      :heading_3 => "MyString",
      :phrase_a_3 => "MyString",
      :value_type_3 => "MyString",
      :ref_table_a_3 => "MyString",
      :ref_table_b_3 => "MyString",
      :phrase_b_3 => "MyString",
      :phrase_c_3 => "MyString",
      :required_y_n_3 => "MyString",
      :display_order => 1,
      :status => "MyString",
      :parent_question_id => 1,
      :description => "MyString"
    ).as_new_record)
  end

  it "renders new question form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => questions_path, :method => "post" do
      assert_select "input#question_heading_1", :name => "question[heading_1]"
      assert_select "input#question_phrase_a_1", :name => "question[phrase_a_1]"
      assert_select "input#question_value_type_1", :name => "question[value_type_1]"
      assert_select "input#question_ref_table_a_1", :name => "question[ref_table_a_1]"
      assert_select "input#question_ref_table_b_1", :name => "question[ref_table_b_1]"
      assert_select "input#question_phrase_b_1", :name => "question[phrase_b_1]"
      assert_select "input#question_phrase_c_1", :name => "question[phrase_c_1]"
      assert_select "input#question_required_y_n_1", :name => "question[required_y_n_1]"
      assert_select "input#question_heading_2", :name => "question[heading_2]"
      assert_select "input#question_phrase_a_2", :name => "question[phrase_a_2]"
      assert_select "input#question_value_type_2", :name => "question[value_type_2]"
      assert_select "input#question_ref_table_a_2", :name => "question[ref_table_a_2]"
      assert_select "input#question_ref_table_b_2", :name => "question[ref_table_b_2]"
      assert_select "input#question_phrase_b_2", :name => "question[phrase_b_2]"
      assert_select "input#question_phrase_c_2", :name => "question[phrase_c_2]"
      assert_select "input#question_required_y_n_2", :name => "question[required_y_n_2]"
      assert_select "input#question_heading_3", :name => "question[heading_3]"
      assert_select "input#question_phrase_a_3", :name => "question[phrase_a_3]"
      assert_select "input#question_value_type_3", :name => "question[value_type_3]"
      assert_select "input#question_ref_table_a_3", :name => "question[ref_table_a_3]"
      assert_select "input#question_ref_table_b_3", :name => "question[ref_table_b_3]"
      assert_select "input#question_phrase_b_3", :name => "question[phrase_b_3]"
      assert_select "input#question_phrase_c_3", :name => "question[phrase_c_3]"
      assert_select "input#question_required_y_n_3", :name => "question[required_y_n_3]"
      assert_select "input#question_display_order", :name => "question[display_order]"
      assert_select "input#question_status", :name => "question[status]"
      assert_select "input#question_parent_question_id", :name => "question[parent_question_id]"
      assert_select "input#question_description", :name => "question[description]"
    end
  end
end
