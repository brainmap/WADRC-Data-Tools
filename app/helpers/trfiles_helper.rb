module TrfilesHelper
	# from Questionform helper
def trfile_draw_text_field(p_question_id, p_value_number,p_size,p_default_value, p_value,p_js,p_required_y_n)

    p_js_array = p_js.split(",")
    
     if p_js_array.include?("numeric")
       if p_required_y_n == "required"
          text_field_tag "value_"+p_value_number+"["+p_question_id.to_s+"][]",(p_value.try(:strip) or p_default_value), :required=>TRUE, :size=>p_size, :onchange => "if ( isNaN(this.value)){alert('The field needs to be all numeric.');this.value =''}"
      else
         text_field_tag "value_"+p_value_number+"["+p_question_id.to_s+"][]",(p_value.try(:strip) or p_default_value), :size=>p_size, :onchange => "if ( isNaN(this.value)){alert('The field needs to be all numeric.');this.value =''}"
        
      end                                                                              
     elsif p_js_array.include?("calculated_bmi")
            text_field_tag "value_"+p_value_number+"["+p_question_id.to_s+"][]",(p_value.try(:strip) or p_default_value) , :size=>p_size, 
            :onchange => "if ( isNaN(this.value)){alert('The field needs to be all numeric.');this.value ='';t3 =document.getElementById('value_3_"+p_question_id.to_s+"_');t3.value=''}
                          else{t1 =document.getElementById('value_1_"+p_question_id.to_s+"_');t2 =document.getElementById('value_2_"+p_question_id.to_s+"_');
                                 t3 =document.getElementById('value_3_"+p_question_id.to_s+"_');t3.value= Math.round(t2.value/((0.0254*t1.value)*(0.0254*t1.value)))}"

     elsif p_js_array.include?("calculated_bmi_cm")
            text_field_tag "value_"+p_value_number+"["+p_question_id.to_s+"][]",(p_value.try(:strip) or p_default_value) , :size=>p_size, 
            :onchange => "if ( isNaN(this.value)){alert('The field needs to be all numeric.');this.value ='';t3 =document.getElementById('value_3_"+p_question_id.to_s+"_');t3.value=''}
                          else{t1 =document.getElementById('value_1_"+p_question_id.to_s+"_');t2 =document.getElementById('value_2_"+p_question_id.to_s+"_');
                                 t3 =document.getElementById('value_3_"+p_question_id.to_s+"_');t3.value= Math.round(t2.value/((0.01*t1.value)*(0.01*t1.value)))}"
         
    else
         if p_required_y_n ==  "required"
             text_field_tag "value_"+p_value_number+"["+p_question_id.to_s+"][]",(p_value.try(:strip) or p_default_value) , :required=>TRUE,:size=>p_size 
         else
            text_field_tag "value_"+p_value_number+"["+p_question_id.to_s+"][]",(p_value.try(:strip) or p_default_value) ,:size=>p_size 
         end
      end
  end
  
  def trfile_draw_text_area(p_question_id, p_size,p_default_value, p_value, p_required_y_n) # removed p_value_number,
    if p_required_y_n ==  "required"
      text_area_tag("value["+p_question_id.to_s+"][]",(p_value.try(:strip) or p_default_value),:size => p_size, :required =>TRUE)
    else
      text_area_tag("value["+p_question_id.to_s+"][]",(p_value.try(:strip) or p_default_value),:size => p_size) 
    end
  end

end

def trfile_draw_hidden_field(p_question_id, p_value_number,p_default_value, p_value)
    hidden_field_tag "value_"+p_value_number+"["+p_question_id.to_s+"][]",(p_value.try(:strip) or p_default_value) 
end