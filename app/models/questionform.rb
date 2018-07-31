class Questionform < ActiveRecord::Base
  
    has_many :questionform_questions, :dependent => :destroy
    has_many :questionform_scan_procedures, :dependent => :destroy


  def displayform_pdf(p_q_data_form_id, p_q_form_id,p_appointment,p_vgroup)
  	# using model function - questionforms.displayform view  crossed with questionnaire.show
    @enumbers = p_vgroup.enrollments
    v_enumber_array = []
    @enumbers.each do |enum|
          v_enumber_array.push(enum.enumber)
    end
     sp_list = p_vgroup.scan_procedures.collect {|sp| sp.id}.join(",")
     sp_array =[]
     sp_array = sp_list.split(',').map(&:to_i)
     @questionform =Questionform.find(p_q_form_id)
     sp_name_array = []
     sp_array.each do |sp|
         sp_name_array.push(ScanProcedure.find(sp).codename)
     end
     @q_data_form = QDataForm.find(p_q_data_form_id)

     @spformdisplays = Questionformnamesp.where("questionform_id in (?) and scan_procedure_id in (?)",p_q_form_id,sp_array)
    if !@spformdisplays.nil?
       v_form_name = @spformdisplays.sort_by(&:form_name).collect {|sp| sp.form_name }.join(", ")
      if v_form_name.empty?
          v_form_name = @questionform.long_description
      end
    end
  
     @questionform_questions = QuestionformQuestion.where("( question_id not in (select question_id from question_scan_procedures)
                                                           or (question_id in 
                                                                   (select question_id from question_scan_procedures where  include_exclude ='include' and scan_procedure_id in (?))
                                                                and
                                                             question_id not in 
                                        (select question_id from question_scan_procedures where include_exclude ='exclude' and scan_procedure_id in (?)))) and (questionform_id = ?)",
                                                   sp_array,sp_array,p_q_form_id).sort_by(&:display_order)

    connection = ActiveRecord::Base.connection();
    v_params_q_data_id = []
    v_value_array = []
    pdf = Prawn::Document.new
    pdf.font('Helvetica', size: 10)
    v_value = v_form_name+"    "+p_appointment.appointment_date.to_s+" "+v_enumber_array.join(" ,")
    pdf.text v_value
    v_value = sp_name_array.join(", ")
    pdf.text v_value
    pdf.text ""
    @questionform_questions.each do |qfq|
      @question = Question.find(qfq.question_id)
      # pass @question to draw_question
      v_params_q_data_id[qfq.question_id] = "" #"33" 
      if !@q_data_form.blank?  # get this q_data_form_id / question_id ==> assuming no duplicate question_id in one form
      sql = "select distinct q_data.id from q_data where q_data_form_id ="+@q_data_form.id.to_s+" and 
             q_data.question_id  ="+@question.id.to_s
        
        results = connection.execute(sql)
        results.each do |id|
        v_params_q_data_id[qfq.question_id] =  id.try(:to_s)
        v_params_q_data_id[qfq.question_id]= v_params_q_data_id[qfq.question_id].gsub("[","").gsub("]","")
      end
      end 
      # added check to see if q_data exisits - cai 20131003 -- not sure how a q_data didn't get made
      if v_params_q_data_id[qfq.question_id].length > 0 and QDatum.exists?(v_params_q_data_id[qfq.question_id])
       #@q_data = QDatum.find(params["q_data_id["+qfq.question_id.to_s+"]"])
            @q_data = QDatum.find(v_params_q_data_id[qfq.question_id])
      else
       @q_data = QDatum.new
       @q_data.value_1 = @question.default_val_1
       @q_data.value_2 = @question.default_val_2
       @q_data.value_3 = @question.default_val_3
      end

      if !@question.heading_1.blank?
         v_value = @question.heading_1.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
         v_value_array = v_value.split("<br>")
         v_value_array.each do |v_value_| 
            pdf.text v_value_
         end
      end 
      if !@question.phrase_a_1.blank?
         v_value = @question.phrase_a_1.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
         v_value_array = v_value.split("<br>")
         v_value_array.each do |v_value_| 
            pdf.text v_value_
         end 
      end 
      if !@question.phrase_b_1.blank? 
         v_value = @question.phrase_b_1.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
         v_value_array = v_value.split("<br>")
         v_value_array.each do |v_value_| 
            pdf.text v_value_
         end 
      end 

      if !@question.value_type_1.blank?   # follow order in array in question form edit
           val_array =[]
           if !@q_data.value_1.blank?
              val_array = @q_data.value_1.split(',')
           end
           if @question.value_type_1 == "textarea" or @question.value_type_1 == "textarea_3x60"  # walk thru each value_type --- get each disoplay value  %>
               v_value = @q_data.value_1.html_safe.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
               v_value_array = v_value.split("<br>")
               v_value_array.each do |v_value_| 
                  pdf.text v_value_
               end
           elsif @question.value_type_1 == "dropdown"
               if @question.ref_table_a_1 == "lookup_refs" 
                  if !@q_data.value_1.blank?
                      v_lookup_refs =  LookupRef.where("label in (?) and ref_value in (?)",@question.ref_table_b_1,@q_data.value_1)
                      v_value = @q_data.value_1+"  "+v_lookup_refs.first.description
                      pdf.text v_value
                  end
               end 
           elsif @question.value_type_1 == "date" or @question.value_type_1 == "date_dob"  
                    if !@q_data.value_1.blank?
                          v_tmp_date = Date.strptime(@q_data.value_1,'%Y-%m-%d')
                          v_value = v_tmp_date.html_safe.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                          pdf.text v_value
                    end 
           elsif @question.value_type_1 == "date_time"  
                    if !@q_data.value_1.blank?
                          v_tmp_datetime = DateTime.strptime(@q_data.value_1,'%Y-%m-%d-%H-%M')
                          v_value = v_tmp_date.html_safe.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                          pdf.text v_value
                     end
                  
           elsif @question.value_type_1 == "time"                      
                    if !@q_data.value_1.blank?
                          v_tmp_time = Time.strptime(@q_data.value_1,'%H-%M')
                          v_value = v_tmp_date.html_safe.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                          pdf.text v_value
                    end
                  
           elsif @question.value_type_1 == "text_5" or @question.value_type_1 == "text_10" or @question.value_type_1 == "text_20" or @question.value_type_1 == "text_30" or  @question.value_type_1 == "text_50" or  @question.value_type_1 == "text_70" or  @question.value_type_1 == "text_90" or  @question.value_type_1 == "date" or  @question.value_type_1 == "date_dob"
               v_value =  @q_data.value_1.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
               v_value_array = v_value.split("<br>")
               v_value_array.each do |v_value_| 
                     pdf.text v_value_ 
              end                 
           elsif @question.value_type_1 == "checkbox_1_col"  or  @question.value_type_1 == "checkbox_in_line" or  @question.value_type_1 == "radio_1_col"  or @question.value_type_1 == "radio_in_line" 
                if @question.ref_table_a_1 == "lookup_refs" 
                    v_lookup_refs =  LookupRef.where("label in (?) and ref_value in (?)",@question.ref_table_b_1,@q_data.value_1)
                    v_value = @q_data.value_1+"  "+v_lookup_refs.first.description
                    pdf.text v_value
                end   
          end  # question type    
        end # !@question.value_type_1.blank?

        if !@question.phrase_c_1.blank?
            v_value = @question.phrase_c_1.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
            v_value_array = v_value.split("<br>")
            v_value_array.each do |v_value_| 
                pdf.text v_value_ 
            end  
        end 

        if !@question.heading_2.blank?
            v_value = @question.heading_2.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
            v_value_array = v_value.split("<br>")
            v_value_array.each do |v_value_| 
                pdf.text v_value_ 
            end
        end
        if !@question.phrase_a_2.blank? 
            v_value = @question.phrase_a_2.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
            v_value_array = v_value.split("<br>")
            v_value_array.each do |v_value_| 
                pdf.text v_value_ 
            end  
        end  
        if !@question.phrase_b_2.blank?
            v_value = @question.phrase_b_2.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
            v_value_array = v_value.split("<br>")
            v_value_array.each do |v_value_| 
                pdf.text v_value_ 
            end  
         end  
         if !@question.value_type_2.blank?   # follow order in array in question form edit
            val_array =[]
            if !@q_data.value_2.blank?
               val_array = @q_data.value_2.split(',')
            end
            if @question.value_type_2 == "textarea"  or @question.value_type_2 == "textarea_3x60"      
               v_value = @q_data.value_2.html_safe.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
               v_value_array = v_value.split("<br>")
               v_value_array.each do |v_value_| 
                  pdf.text v_value_ 
              end
        

            elsif @question.value_type_2 == "dropdown"
                if @question.ref_table_a_2 == "lookup_refs"  
                    v_lookup_refs =  LookupRef.where("label in (?) and ref_value in (?)",@question.ref_table_b_2,@q_data.value_2),
                    v_value = @q_data.value_1+"  "+v_lookup_refs.first.description
                    pdf.text v_value
               end  ## use ref_table_b_2 %>


            elsif @question.value_type_2 == "date" or  @question.value_type_2 == "date_dob"
                    if !@q_data.value_2.blank?
                          v_tmp_date = Date.strptime(@q_data.value_2,'%Y-%m-%d') 
                          v_value = v_tmp_date.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                          pdf.text v_value 
                     end             
            elsif @question.value_type_2 == "date_time"  
                    if !@q_data.value_2.blank?
                          v_tmp_datetime = DateTime.strptime(@q_data.value_2,'%Y-%m-%d-%H-%M') 
                          v_value = v_tmp_date.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                          pdf.text v_value 
                    end
                    
             elsif @question.value_type_2 == "time"                      
                    if !@q_data.value_2.blank?
                          v_tmp_time = Time.strptime(@q_data.value_2,'%H-%M') 
                          v_value = v_tmp_date.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                          pdf.text v_value 
                   end
                 
             elsif @question.value_type_2 == "text_5" or @question.value_type_2 == "text_10" or @question.value_type_2 == "text_20" or @question.value_type_2 == "text_30" or @question.value_type_2 == "text_50" or @question.value_type_2 == "text_70" or @question.value_type_2 == "text_90" or @question.value_type_2 == "date" or @question.value_type_2 == "date_dob" 
                v_value = @q_data.value_2.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                v_value_array = v_value.split("<br>")
                v_value_array.each do |v_value_| 
                    pdf.text v_value_
                end
  
             elsif @question.value_type_2 == "checkbox_1_col" or @question.value_type_2 == "checkbox_in_line" or @question.value_type_2 == "radio_1_col" or @question.value_type_2 == "radio_in_line" 
                if @question.ref_table_a_2 == "lookup_refs" 
                    v_lookup_refs =  LookupRef.where("label in (?) and ref_value in (?)",@question.ref_table_b_2,@q_data.value_2),
                    v_value = @q_data.value_1+"  "+v_lookup_refs.first.description
                    pdf.text v_value
                end

             end # question type
        end # !@question.value_type_2.blank?
    if !@question.phrase_c_2.blank? 
       v_value = @question.phrase_c_2.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
         v_value_array = v_value.split("<br>")
         v_value_array.each do |v_value_| 
            pdf.text v_value_ 
         end
     end 


    if !@question.heading_3.blank? 
         v_value = @question.heading_3.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
         v_value_array = v_value.split("<br>")
         v_value_array.each do |v_value_| 
            pdf.text v_value_
          end
     end
    if !@question.phrase_a_3.blank? 
       v_value = @question.phrase_a_3.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
         v_value_array = v_value.split("<br>")
         v_value_array.each do |v_value_| 
            pdf.text v_value_ 
        end
     end 
    if !@question.phrase_b_3.blank? 
       v_value = @question.phrase_b_3.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
         v_value_array = v_value.split("<br>")
         v_value_array.each do |v_value_| 
            pdf.text v_value_  
         end
     end 
  
    if !@question.value_type_3.blank?   # follow order in array in question form edit
      val_array =[]
      if !@q_data.value_3.blank?
        val_array = @q_data.value_3.split(',')
      end
      if @question.value_type_3 == "textarea" or  @question.value_type_3 == "textarea_3x60" 
             v_value = @q_data.value_3.html_safe.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
             v_value_array = v_value.split("<br>")
             v_value_array.each do |v_value_| 
                 pdf.text v_value_
             end
       elsif @question.value_type_3 == "textarea_3x60"   # walk thru each value_type --- get each disoplay value  %>      
             v_value =  @q_data.value_3.html_safe.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
             v_value_array = v_value.split("<br>")
             v_value_array.each do |v_value_| 
                pdf.text v_value_
             end
       elsif @question.value_type_3 == "dropdown"
          if @question.ref_table_a_3 == "lookup_refs"  
                    v_lookup_refs =  LookupRef.where("label in (?) and ref_value in (?)",@question.ref_table_b_3,@q_data.value_3),
                    v_value = @q_data.value_1+"  "+v_lookup_refs.first.description
                    pdf.text v_value
          end

       elsif @question.value_type_3 == "date" or  @question.value_type_3 == "date_dob" 
                    if !@q_data.value_3.blank?
                          v_tmp_date = Date.strptime(@q_data.value_3,'%Y-%m-%d') 
                          v_value = v_tmp_date.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                          pdf.text v_value
                     end    
              
        elsif @question.value_type_3 == "date_time"  
                    if !@q_data.value_3.blank?
                          v_tmp_datetime = DateTime.strptime(@q_data.value_3,'%Y-%m-%d-%H-%M') 
                          v_value = v_tmp_date.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                          pdf.text v_value
                     end
                   
         elsif @question.value_type_3 == "time"                      
                    if !@q_data.value_3.blank?
                          v_tmp_time = Time.strptime(@q_data.value_3,'%H-%M') 
                          v_value = v_tmp_date.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
                          pdf.text v_value
                   end
                  

        elsif @question.value_type_3 == "text_5" or @question.value_type_3 == "text_10" or  @question.value_type_3 == "text_20" or @question.value_type_3 == "text_30" or @question.value_type_3 == "text_50"  or @question.value_type_3 == "text_70"  or @question.value_type_3 == "text_90" or @question.value_type_3 == "date" or  @question.value_type_3 == "date_dob" 
            v_value = @q_data.value_3.gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
            v_value_array = v_value.split("<br>")
            v_value_array.each do |v_value_| 
                pdf.text v_value_
            end 
        elsif @question.value_type_3 == "checkbox_1_col" or  @question.value_type_3 == "checkbox_in_line" or @question.value_type_3 == "radio_1_col" or  @question.value_type_3 == "radio_in_line"
           if @question.ref_table_a_3 == "lookup_refs" 
                    v_lookup_refs =  LookupRef.where("label in (?) and ref_value in (?)",@question.ref_table_b_3,@q_data.value_3),
                    v_value = @q_data.value_1+"  "+v_lookup_refs.first.description
                    pdf.text v_value
            end

         end # question type
       end  # !@question.value_type_3.blank?
       if !@question.phrase_c_3.blank? 
            v_value = @question.phrase_c_3.try(:html_safe).gsub("&nbsp;"," ").gsub("</b>","").gsub("<b>","").gsub("<b/>","")
         v_value_array = v_value.split("<br>")
         v_value_array.each do |v_value_| 
            pdf.text v_value_
         end    
       end 







    end # questionform_questions


    return pdf

  
  end
end
