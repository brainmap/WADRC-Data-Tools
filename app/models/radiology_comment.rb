class RadiologyComment < ActiveRecord::Base
  
  belongs_to :visit 
  

   EXCLUDED_REPORT_ATTRIBUTES = [:rad_path, :q2_flag,:load_date,:created_at, :updated_at, :editable_flag,:rmr_rad, :scan_number_rad]
  acts_as_reportable


  
  # change to text
  def combined_radiology_comments
    var =''
   if !comment_text_1.blank?
     var = var + comment_text_1
   end
  if !comment_text_2.blank?
      var = var + comment_text_2
  end 
  if !comment_text_3.blank?
      var = var + comment_text_3
  end
  if !comment_text_4.blank?
      var = var + comment_text_4
  end
  if !comment_text_5.blank?
      var = var + comment_text_5
  end
    return var
  end
  
  
  # change to html
  def combined_radiology_comments_html
    var =''
   if !comment_html_1.blank?
     var = var + comment_html_1
   end
  if !comment_html_2.blank?
      var = var + comment_html_2
  end 
  if !comment_html_3.blank?
      var = var + comment_html_3
  end
  if !comment_html_4.blank?
      var = var + comment_html_4
  end
  if !comment_html_5.blank?
      var = var + comment_html_5
  end
    return var
  end  

  
  # change to html
  def combined_radiology_header_comments_html
    var =''
   if !comment_header_html_1.blank?
     var = var + comment_header_html_1
   end
  if !comment_header_html_2.blank?
      var = var + comment_header_html_2
  end 
  if !comment_header_header_html_3.blank?
      var = var + comment_header_html_3
  end
  if !comment_header_html_4.blank?
      var = var + comment_header_html_4
  end
  if !comment_header_html_5.blank?
      var = var + comment_header_html_5
  end
  if !comment_header_html_6.blank?
      var = var + comment_header_html_6
  end
    return var
  end  
  
  def radiology_link
       var ='<a href="https://www.radiology.wisc.edu/protected/neuroResearchScans/'+rad_path+'" target="_blank">Radiology Site</a>'
       return var
  end


  
    def load_paths(v_months_back)
      # pass in how far back to go, default is 3 month for visit date
      # select visit_id, rmr, scan_number from visits where visits.date > sysdate - 3 months
      # and visits.id not in (select visit_id from radiology_comments where rad_path is not null) 
      # get the listing page 
      # get each new path - match on rmr and scan_number 

      agent = Mechanize.new
      # this gives back a listing page - the RMR sent shouldn't be important
      page = agent.get('https://www.radiology.wisc.edu/protected/neuroResearchScans/scanList.php?origin=searchForm&subjID=RMRaic004440')


      @response = page.content
      doc = Hpricot(@response)
      pars = Array.new  
      # ?? put the doc into array? -- faster?

      # add dates back?
      # there are 5 visits with "blank" rmr 
      past_time = Time.new - (v_months_back.to_i).month
    v_past_date = past_time.strftime("%Y-%m-%d")
      time = Time.new
      v_date = time.strftime("%m/%d/%Y")

      puts v_date
      @visits = Visit.where(" visits.date > '"+v_past_date+"'  and length(visits.rmr)>0 and length(visits.scan_number) > 0 
               and visits.id not in (select radiology_comments.visit_id from radiology_comments where rad_path is not null)").all
      puts "count of visits "+@visits.count.to_s

      @visits.each do |v|  
         rmr = v.rmr
         scan_number = v.scan_number
         doc.search("//tr").each do |p| 

           var = p.to_s
  # puts var and return
         	 var = var.gsub('<td>','')
         	 var = var.gsub('<td align="center">','')
         	 var = var.gsub('<tr>','')
         	 var = var.gsub('</tr>','')	
         	 var = var.gsub('<a href="','')
         	 var = var.gsub('</a>','')
         	 var = var.gsub('">','')   
           if (var.include? rmr )     &&  (var.include? scan_number.to_s)
             pars = var.split('</td>')
             rad_path =pars[1].to_s.gsub(rmr,"")
             rad_path = rad_path.gsub('" title="urgent','')

             sql = "Insert into radiology_comments(visit_id,rmr,scan_number,rad_path,load_date)Values("+v.id.to_s+",'"+rmr+"','"+scan_number.to_s+"','"+rad_path+"','"+v_date+"')"
             connection = ActiveRecord::Base.connection();
              results = connection.execute(sql)
           end  
         end   
      end
    end
  

  def load_comments(v_months_back)
       agent = Mechanize.new
       # Comment_html_1 only 500 long
        past_time = Time.new - (v_months_back.to_i).month
          v_past_date = past_time.strftime("%Y-%m-%d")
       @radiology_comments = RadiologyComment.where(" trim(radiology_comments.rad_path) is not null and  (radiology_comments.comment_html_1 is null
                     OR radiology_comments.comment_header_html_1 is null
                     OR radiology_comments.visit_id in (select visits.id from visits where visits.date >  '"+v_past_date+"' )  ) " )
#                      OR radiology_comments.comment_header_html_1 is null

      @radiology_comments = RadiologyComment.where(" trim(radiology_comments.rad_path) is not null and radiology_comments.id = 1106")
       @radiology_comments.each do |r|
          # sleep for a minute or so to not seem like scripts
           sleep(97)
puts "============ visit_id ="+r.visit_id.to_s

         page = agent.get('https://www.radiology.wisc.edu/protected/neuroResearchScans/'+r.rad_path)
         @response = page.content
         doc = Hpricot(@response)
         doc_string = doc.to_s
             doc_string = doc_string.gsub("<br />","<br/> ")
              doc_string = doc_string.gsub(/\s+/, " ").strip
               doc_string = doc_string.gsub('&quot;','"')
                doc_string = doc_string.gsub("&nbsp;"," ")
                 doc_string = doc_string.gsub("  "," ")
                  doc_string = doc_string.gsub("  "," ")
                   doc_string = doc_string.gsub("  "," ")
                    doc_string = doc_string.gsub("  "," ")
                     doc_string = doc_string.gsub("  "," ")

#chomp ?  href="scanDetails.php?req=editTop&editTopScanID=
         doc_string = doc_string.gsub('(opens in a new window)','')
         doc_string = doc_string.gsub('href="https://www.radiology.wisc.edu/protected/neuroResearchScans/scanDetails_compare.php?comparisonSubjID=','"')
         doc_string = doc_string.gsub('onclick="return popitup(','')
         
         doc_string = doc_string.gsub("'https://www.radiology.wisc.edu/protected/neuroResearchScans/scanDetails_compare.php?comparisonSubjID=","('")
         doc_string = doc_string.gsub('<img src="https://www.radiology.wisc.edu//images/icons/mailto.jpg" border="0" ></a>','')
         doc_string = doc_string.gsub('<img src="https://www.radiology.wisc.edu//images/icons/mailto.jpg" border="0" />','')
         doc_string = doc_string.gsub('href="mailto:','"')
         doc_string = doc_string.gsub('href=mailto:','')
         doc_string = doc_string.gsub("href='editStudyDetails.php?studyID","")
         doc_string = doc_string.gsub('href="editStudyDetails.php?studyID=','"')
         doc_string = doc_string.gsub('href="editStudyDetails.php?studyID=','"')
         doc_string = doc_string.gsub('href="scanDetails.php?req=editTop&editTopScanID=','"')
         doc_string = doc_string.gsub('href="scanDelete.php?deleteID=','"')
         doc_string = doc_string.gsub('delete this scan <img src="/images/deleteEntry.gif" border="0" />','')
         doc_string = doc_string.gsub("return confirm('Are you sure you want to delete this scan?')","")
         doc_string = doc_string.gsub('onclick=""','')         
         doc_string = doc_string.gsub("| <a href='https://www.radiology.wisc.edu/login.php'>login to access advanced editing</a> (application administrator only","")
         doc_string = doc_string.gsub("'>edit age/gender <img src='https://www.radiology.wisc.edu/images/icons/edit.gif' border=0","")
         doc_string = doc_string.gsub('edit age/gender <img src="/images/edit.gif" border="0" /></a> | <a href="https://www.radiology.wisc.edu/login.php">login to access advanced editing</a> (application administrator only)</p>','')
         doc_string = doc_string.gsub('| <a href="https://www.radiology.wisc.edu/login.php">login to access advanced editing</a> (application administrator only)','')
         doc_string = doc_string.gsub("href='editAgeGender.php?editAgeGenderScanID=","")
         doc_string = doc_string.gsub('href="editAgeGender.php?editAgeGenderScanID=','"')
         
         doc_string = doc_string.gsub('https://www.radiology.wisc.edu/images/icons','/images')
         
         doc_string = doc_string.gsub('edit age/gender <img src="/images/edit.gif" border="0" /></a> | <a href="https://www.radiology.wisc.edu/login.php">login to access advanced editing</a> (application administrator only)','')
         doc_string = doc_string.gsub('edit age/gender <img src="/images/edit.gif" border="0" />','')
         
         doc_string = doc_string.gsub('https://www.radiology.wisc.edu/images/icons/checkbox.gif','/images/checkbox.gif')
         doc_string = doc_string.gsub('https://www.radiology.wisc.edu/images/icons/checkedbox.gif','/images/checkedbox.gif')
         doc_string =doc_string.gsub('https://www.radiology.wisc.edu/images/icons/radioButton_clicked.gif','/images/radioButton_clicked.gif')
         doc_string =doc_string.gsub('https://www.radiology.wisc.edu/images/icons/radioButton.gif','/images/radioButton.gif')

         doc_string = doc_string.gsub('https://www.radiology.wisc.edu/intranet/images/icons/checkbox.gif','/images/checkbox.gif')
         doc_string = doc_string.gsub('https://www.radiology.wisc.edu/intranet/images/icons/checkedbox.gif','/images/checkedbox.gif')
         doc_string =doc_string.gsub('https://www.radiology.wisc.edu/intranet/images/icons/radioButton_clicked.gif','/images/radioButton_clicked.gif')
         doc_string =doc_string.gsub('https://www.radiology.wisc.edu/intranet/images/icons/radioButton.gif','/images/radioButton.gif')
         
         doc_string = doc_string.gsub('https://www.radiology.wisc.edu/protected/intranet/images/icons/checkbox.gif','/images/checkbox.gif')
         doc_string = doc_string.gsub('https://www.radiology.wisc.edu/protected/intranet/images/icons/checkedbox.gif','/images/checkedbox.gif')
         doc_string =doc_string.gsub('https://www.radiology.wisc.edu/protected/intranet/images/icons/radioButton_clicked.gif','/images/radioButton_clicked.gif')
         doc_string =doc_string.gsub('https://www.radiology.wisc.edu/protected/intranet/images/icons/radioButton.gif','/images/radioButton.gif')
         

         doc_string = doc_string.gsub('</div> <div id="col2">',' ')
         doc_string = doc_string.gsub('<div id="col1" align="right">','<div id="col1" align="left">')
        
         # split out header info
          if !doc_string.index('<b>Scan Details</b><span class="subtitle"> (entered into system').blank?
            header_start_index =doc_string.index('<b>Scan Details</b><span class="subtitle"> (entered into system')+3
          else
            header_start_index =0
          end
          
          if !doc_string.index('<a name="radiologistReview"></a>').blank? 
             header_end_index =doc_string.index('<a name="radiologistReview"></a>')+3
          elsif   !doc_string.index('<b>Radiologist Comments</b>').blank? 
              header_end_index = doc_string.index("<b>Radiologist Comments</b>")-2
          elsif !doc_string.index("<h4>Radiologist Comments</h4>").blank?
              header_end_index = doc_string.index("<h4>Radiologist Comments</h4>")-2 
          else 
              header_end_index = 1    
          end
          
         

         if !doc_string.index('<b>Radiologist Comments</b>').blank? 
           start_index = doc_string.index("<b>Radiologist Comments</b>")-2
         elsif !start_index = doc_string.index("<h4>Radiologist Comments</h4>").blank?
           start_index = doc_string.index("<h4>Radiologist Comments</h4>")-2  
         else
           start_index = 0
         end
       
         if !doc_string.index('<form name="modReview"').blank? 
            end_index =doc_string.index('<form name="modReview"')+3
         elsif !doc_string.index('You must be logged in to submit or modify a review').blank?
            end_index	=doc_string.index("You must be logged in to submit or modify a review")+3
         elsif !doc_string.index("If this scan has been updated:").blank?
            end_index	=doc_string.index("If this scan has been updated:")+3
         else
          end_index = 1497
         end
         
         doc_string = doc_string.gsub("'","`")
         doc_header_string = doc_string[header_start_index..header_end_index]
         doc_sub_string = doc_string[start_index..end_index]
         # some pages have slight difference in start index - leaving a ">"
         doc_sub_string = doc_sub_string.gsub('<br/> <h4>Radiologist Comments</h4>','<b>Radiologist Comments</b>')
         doc_sub_string = doc_sub_string.gsub('> <br/> <b>Radiologist Comments',' <br/> <b>Radiologist Comments')
         doc_sub_string = doc_sub_string.gsub('> <br/> <h4>Radiologist Comments</h4','<b>Radiologist Comments</b>')
         doc_sub_string = doc_sub_string.gsub('iv> <br/> <h4>Radiologist Comments</','<b>Radiologist Comments</b>')
         doc_sub_string = doc_sub_string.gsub('> <b>Radiologist Comments</b>','<b>Radiologist Comments</b>')
          doc_sub_string = doc_sub_string.gsub('> <h4>Radiologist Comments</h4>','<b>Radiologist Comments</b>')

         # escape the ' in doc_sub_string

         if doc_sub_string.length > 0
            comment_html_2 = ""
            if doc_sub_string.length > 499 
               comment_html_2 = doc_sub_string[499..998]
            end 
            comment_html_3 = ""
            if doc_sub_string.length > 998 
               comment_html_3 = doc_sub_string[999..1497]
            end
            
            comment_html_4 = ""
            if doc_sub_string.length > 1497 
               comment_html_4 = doc_sub_string[1498..1997]
            end  
            
            comment_html_5 = ""
            if doc_sub_string.length > 1997 
               comment_html_5 = doc_sub_string[1998..2496]
            end  
            
            # header
            comment_header_html_2 = ""
            if doc_header_string.length > 499 
               comment_header_html_2 = doc_header_string[499..998]
            end 
            comment_header_html_3 = ""
            if doc_header_string.length > 998 
               comment_header_html_3 = doc_header_string[999..1497]
            end
            
            comment_header_html_4 = ""
            if doc_header_string.length > 1497 
               comment_header_html_4 = doc_header_string[1498..1997]
            end  
            
            comment_header_html_5 = ""
            if doc_header_string.length > 1997 
               comment_header_html_5 = doc_header_string[1998..2496]
            end

            comment_header_html_6 = ""
            if doc_header_string.length > 2497 
               comment_header_html_6 = doc_header_string[2497..2996]
            end
            

            
            sql = "update radiology_comments set comment_html_1 = '"+doc_sub_string[0..498]+
            "',comment_html_2 = '"+comment_html_2+"', comment_html_3 = '"+comment_html_3+"',
             comment_html_4 = '"+comment_html_4+"',  comment_html_5 = '"+comment_html_5+"'  ,
             comment_header_html_1 = '"+doc_header_string[0..498]+
             "',comment_header_html_2 = '"+comment_header_html_2+"', comment_header_html_3 = '"+comment_header_html_3+"',
              comment_header_html_4 = '"+comment_header_html_4+"',  comment_header_html_5 = '"+comment_header_html_5+"'  ,
                comment_header_html_6 = '"+comment_header_html_6+"'  ,
              comment_text_1=null,comment_text_2=null,comment_text_3=null,comment_text_4=null,
              comment_text_5 =null,q1_flag= null
                   where radiology_comments.rad_path ='"+r.rad_path+"'    "
            connection = ActiveRecord::Base.connection();
            begin            
               results = connection.execute(sql)    
             rescue
               puts "ERROR!!!!!!!!! with "+sql
             end
                 
            sql = "commit"
            connection.execute(sql)
                              
          end      
       end
  end

  def load_text

    sql = "select id,comment_html_1,comment_html_2,comment_html_3,comment_html_4,comment_html_5
            from radiology_comments where comment_html_1 is not null and (comment_text_1 is null or trim(q1_flag) is null or trim(q1_flag) ='' )"
            # comment_text_1 might have pre-review text
            
            connection = ActiveRecord::Base.connection();
            results = connection.execute(sql)
            @results = RadiologyComment.find_by_sql(sql)
                  
          @results.each do |row|
  puts " radiology_comments.id ="+row.id.to_s
            comment_text_1 =""
            comment_text_2 =""
            comment_text_3 =""
            comment_text_4 =""
            comment_text_5 =""
             var = row.comment_html_1+row.comment_html_2+row.comment_html_3+row.comment_html_4+row.comment_html_5
             # set q1_flag
             v_q1_flag ='' 
             if !var.index('<span class="warning">Summary:</span> <span class="warning">normal</span>').blank?
                v_q1_flag = 'Summary: normal'
             elsif !var.index('<span class="warning">Summary:</span> <span class="warning">abnormal, follow-up recommended</span>').blank?
                v_q1_flag = 'Summary: abnormal, follow-up recommended'
             elsif !var.index('<span class="warning">Summary:</span> <span class="warning">abnormal, no follow-up recommended</span>').blank?
                    v_q1_flag = 'Summary: abnormal, no follow-up recommended'
             end
             var = var.gsub('<img src="/images/radioButton.gif" />','N=')
             var = var.gsub('<img src="/images/radioButton_clicked.gif" />','Y=')
             var = var.gsub('<img src="/images/checkbox.gif" />','N=')
             var = var.gsub('<img src="/images/checkedbox.gif" />','Y=')
             var = var.gsub('<br/>','char(10)')
             var = var.gsub('<BR/>','char(10)')
             var = var.gsub('<br />','char(10)')
             var = var.gsub('<BR />','char(10)')
             var = var.gsub('<br>','char(10)')
             var = var.gsub('<BR>','char(10)')
             
             var = var.gsub('<b>','')
             var = var.gsub('</b>','')
             
              var = var.gsub('<span class="subtitle">','')
              var = var.gsub('</span>','')
              var = var.gsub('<div id="col1" align="left">','\n')
              var = var.gsub('<span class="warning">','')
              var = var.gsub('</div>','')
              var = var.gsub('<div class="clear">','')
              var = var.gsub('<div id="col2">','')
              
              var = var.gsub('<div class="box_expand">','')
              var = var.gsub('<div class="topright">','') 
              var = var.gsub('<div class="topleft">','') 
              var = var.gsub('<div class="content">','')
              var = var.gsub('<strong>','')
              var = var.gsub('</strong>','')
              var = var.gsub('<div class="bottomright">','')
               var = var.gsub('<div class="bottomleft">','') 
              
            var.gsub!('\n',"char(10)")
            var.gsub!("\n","char(10)")
            
            # remove leading white space
            var = var.strip
            # remove leading line return
            var = var.sub('char(10)',"")
             var = var.sub("char(10)","")
             # char(10) is spanning line break
             var = var.gsub('char(10)',"\n")
             var = var.gsub("char(10)","\n")
             # seems to be getting line breaks ok and remove first line break
                    
             var = var.gsub("'","`")
             comment_text_1 = var[0..498]
             
              # escape the ' in var
              if var.length > 0
                 comment_text_2 = ""
                 if var.length > 499 
                    comment_text_2 = var[499..998]
                 end 
                 comment_text_3 = ""
                 if var.length > 998 
                    comment_text_3 = var[999..1497]
                 end

                 comment_text_4 = ""
                 if var.length > 1497 
                    comment_text_4 = var[1498..1997]
                 end  

                 comment_text_5 = ""
                 if var.length > 1997 
                    comment_text_5 = var[1998..2496]
                 end
              end
             
              sql_update = "update radiology_comments set comment_text_1 = '"+comment_text_1+
              "',comment_text_2 = '"+comment_text_2+"', comment_text_3 = '"+comment_text_3+"',
               comment_text_4 = '"+comment_text_4+"',  comment_text_5 = '"+comment_text_5+"',
                 q1_flag ='"+v_q1_flag+"'  
                     where radiology_comments.id = "+row.id.to_s
                     
#   puts "====="+sql_update               
                     
              connection = ActiveRecord::Base.connection();
            results = connection.execute(sql_update)
            sql = "commit"
            connection.execute(sql)
            
            sql_update = "update radiology_comments 
            set      comment_text_1= replace(comment_text_1,'char(10)',char(10)),
             comment_text_2= replace(comment_text_2,'char(10)',char(10)),
              comment_text_3= replace(comment_text_3,'char(10)',char(10)),
               comment_text_4= replace(comment_text_4,'char(10)',char(10)),
                comment_text_5= replace(comment_text_5,'char(10)',char(10))"
                
                  connection = ActiveRecord::Base.connection();
                results = connection.execute(sql_update)
                sql = "commit"
                connection.execute(sql)
     
                     
          end  
            
     
  end

  
end
