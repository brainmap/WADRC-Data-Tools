require File.expand_path(File.join(File.dirname(__FILE__), '../../../../test/test_helper')) 

class Person
  attr_accessor :name, :id
  def initialize name, id = nil
    @name, @id = name, id
  end
  def to_param
    id.to_s
  end
end

class AutoCompleteFormHelperTest < Test::Unit::TestCase

  include AutoCompleteMacrosHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormHelper
  
  include AutoCompleteFormHelper

  def setup

    @existing_person = Person.new "Existing Person", 1234
    @person = Person.new "New Person"

    controller_class = Class.new do
      def url_for(options)
        url =  "http://www.example.com/"
        url << options[:action].to_s if options and options[:action]
        url
      end
    end
    @controller = controller_class.new
    
  end
  
  def test_two_auto_complete_fields_have_different_ids
    id_attribute_pattern = /id=\"[^\"]*\"/i
    _erbout = ''
    _erbout2 = ''
    fields_for('group[person_attributes][]', @person) do |f|
      _erbout.concat f.text_field_with_auto_complete(:name)
      _erbout2.concat f.text_field_with_auto_complete(:name)
    end
    assert_equal [], _erbout.scan(id_attribute_pattern) & _erbout2.scan(id_attribute_pattern)
  end

  def test_compare_macro_to_fields_for
    standard_auto_complete_html =
      text_field_with_auto_complete :person, :name
  
    _erbout = ''
    fields_for('group[person_attributes][]', @person) do |f|
      _erbout.concat f.text_field_with_auto_complete(:name)
    end
  
    assert_equal standard_auto_complete_html,
      _erbout.gsub(/group\[person_attributes\]\[\]/, 'person').gsub(/person_[0-9]+_name/, 'person_name').gsub(/paramName:'person\[name\]'/, '')
  end
  
  def test_ajax_url
    _erbout = ''
    fields_for('group[person_attributes][]', @person) do |f|
      _erbout.concat f.text_field_with_auto_complete(:name)
    end
    assert _erbout.index('http://www.example.com/auto_complete_for_person_name')
  end
  
  def test_ajax_param
    _erbout = ''
    fields_for('group[person_attributes][]', @person) do |f|
      _erbout.concat f.text_field_with_auto_complete(:name)
    end
    assert _erbout.index("{paramName:'person[name]'}")
  end
  
  def test_object_value
    _erbout = ''
    fields_for('group[person_attributes][]', @existing_person) do |f|
      _erbout.concat f.text_field_with_auto_complete(:name)
    end
    assert _erbout.index('value="Existing Person"')
  end
  
  def test_auto_index_value_for_existing_record
    _erbout = ''
    fields_for('group[person_attributes][]', @existing_person) do |f|
      _erbout.concat f.text_field_with_auto_complete(:name)
    end
    assert _erbout.index("[1234]")
  end
  
  def test_auto_index_value_for_new_record
    _erbout = ''
    fields_for('group[person_attributes][]', @person) do |f|
      _erbout.concat f.text_field_with_auto_complete(:name)
    end
    assert _erbout.index("[]")
  end

end
