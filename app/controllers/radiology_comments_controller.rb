class RadiologyCommentsController < ApplicationController
  # GET /radiology_comments
  # GET /radiology_comments.xml
  def index
    radiology_comments =RadiologyComment.find(:all)
    if params[:radiology_comment].try(:length).nil?
         params[:radiology_comment] =""
    end
    if params[:load_paths].try(:length).nil?
    else
      # months back
     radiology_comments[0].load_paths(params[:load_paths])
      puts "========= in else  load_paths "+params[:load_paths]
    end

    if params[:load_comments].try(:length).nil?
    else
       radiology_comments =RadiologyComment.find(:all)
     radiology_comments[0].load_comments(params[:load_comments])
       # delete, load months back
      puts "========= load_comments ="+params[:load_comments]
      radiology_comments[0].load_text
    end    
    
    radiology_comments[0].load_text # only updating if null 
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
     #@catch = params[:radiology_comment]
     past_time = Time.new - 3.month
     v_past_date = past_time.strftime("%Y-%m-%d")
    if params[:radiology_comment][:rmr].try(:blank?) && params[:radiology_comment][:protocol_id].try(:blank?)

       @radiology_comments = RadiologyComment.where("radiology_comments.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)
                                       and scan_procedures_visits.visit_id in (select visits.id from visits where visits.date > '"+v_past_date+"'))", scan_procedure_array).all
     # get last 3 months or pagation
    else
      if !params[:radiology_comment][:rmr].blank? && params[:radiology_comment][:protocol_id].blank?

        @radiology_comments = RadiologyComment.where("radiology_comments.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)
                            and scan_procedures_visits.visit_id in (select visits.id from visits where visits.rmr in (?)))", scan_procedure_array,params[:radiology_comment][:rmr]).all
      
     elsif  params[:radiology_comment][:rmr].blank? && !params[:radiology_comment][:protocol_id].blank?
      # @protocol_roles = ProtocolRole.where("protocol_id in  (?)", params[:radiology_comment][:protocol_id]).all
        @radiology_comments = RadiologyComment.where("radiology_comments.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)
                            and scan_procedures_visits.scan_procedure_id in (select scan_procedures.id from scan_procedures where scan_procedures.protocol_id in (?)) )",
                                                                                                                       scan_procedure_array,params[:radiology_comment][:protocol_id]).all 
      
     elsif  !params[:radiology_comment][:rmr].blank? && !params[:radiology_comment][:protocol_id].blank?
    #   @protocol_roles = ProtocolRole.where("rmr in  (?) and protocol_id in (?)", params[:radiology_comment][:rmr], params[:radiology_comment][:protocol_id]).all      
        @radiology_comments = RadiologyComment.where("radiology_comments.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)
                           and scan_procedures_visits.scan_procedure_id in (select scan_procedures.id from scan_procedures where scan_procedures.protocol_id in (?))
                           and scan_procedures_visits.visit_id in (select visits.id from visits where visits.rmr in (?)) )",
                                                                            scan_procedure_array,params[:radiology_comment][:protocol_id],params[:radiology_comment][:rmr]).all
      end

   end
     if @radiology_comments.nil?
       @radiology_comments = RadiologyComment.where("radiology_comments.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?)
                                       and scan_procedures_visits.visit_id in (select visits.id from visits where visits.date > '"+v_past_date+"'))", scan_procedure_array).all
     end
    # @radiology_comments = RadiologyComment.where("radiology_comments.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @radiology_comments }
    end
  end

  # GET /radiology_comments/1
  # GET /radiology_comments/1.xml
  def show
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
    @radiology_comment = RadiologyComment.where("radiology_comments.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @radiology_comment }
    end
  end

  # GET /radiology_comments/new
  # GET /radiology_comments/new.xml
  def new
    @radiology_comment = RadiologyComment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @radiology_comment }
    end
  end

  # GET /radiology_comments/1/edit
  def edit
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @radiology_comment = RadiologyComment.where("radiology_comments.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
  end
  

  # POST /radiology_comments
  # POST /radiology_comments.xml
  def create
    @radiology_comment = RadiologyComment.new(params[:radiology_comment])

    respond_to do |format|
      if @radiology_comment.save
        format.html { redirect_to(@radiology_comment, :notice => 'Radiology comment was successfully created.') }
        format.xml  { render :xml => @radiology_comment, :status => :created, :location => @radiology_comment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @radiology_comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /radiology_comments/1
  # PUT /radiology_comments/1.xml
  def update
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @radiology_comment = RadiologyComment.where("radiology_comments.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])

    respond_to do |format|
      if @radiology_comment.update_attributes(params[:radiology_comment])
        format.html { redirect_to(@radiology_comment, :notice => 'Radiology comment was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @radiology_comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /radiology_comments/1
  # DELETE /radiology_comments/1.xml
  def destroy
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
    @radiology_comment = RadiologyComment.where("radiology_comments.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @radiology_comment.destroy

    respond_to do |format|
      format.html { redirect_to(radiology_comments_url) }
      format.xml  { head :ok }
    end
  end
  
    # moved to model
=begin
  def load_paths(v_months_back)  # THIS HAS BEEN MOVED TO MODEL!!!!!!!!!!
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

  def load_comments(v_months_back)   # THIS HAS BEEN MOVED TO MODEL!!!!!!!!!!
       agent = Mechanize.new
       # Comment_html_1 only 500 long
        past_time = Time.new - (v_months_back.to_i).month
          v_past_date = past_time.strftime("%Y-%m-%d")
       @radiology_comments = RadiologyComment.where(" trim(radiology_comments.rad_path) is not null and  (radiology_comments.comment_html_1 is null
                      OR radiology_comments.comment_header_html_1 is null
                     OR radiology_comments.visit_id in (select visits.id from visits where visits.date >  '"+v_past_date+"' )  ) " )
                     


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

#chomp ?
         doc_string = doc_string.gsub('<img src="https://www.radiology.wisc.edu//images/icons/mailto.jpg" border="0" ></a>','')
         doc_string = doc_string.gsub('<img src="https://www.radiology.wisc.edu//images/icons/mailto.jpg" border="0" />','')
         doc_string = doc_string.gsub('href="mailto:','"')
         doc_string = doc_string.gsub('href=mailto:','')
         doc_string = doc_string.gsub("href='editStudyDetails.php?studyID","")
         doc_string = doc_string.gsub('href="editStudyDetails.php?studyID=','"')
         doc_string = doc_string.gsub('href="editStudyDetails.php?studyID=','"')
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
          end
          
          if !doc_string.index('<a name="radiologistReview"></a>').blank? 

             header_end_index =doc_string.index('<a name="radiologistReview"></a>')+3
          elsif   !doc_string.index('<b>Radiologist Comments</b>').blank? 

              header_end_index = doc_string.index("<b>Radiologist Comments</b>")-2
          else

              header_end_index = doc_string.index("<h4>Radiologist Comments</h4>")-2  
          end
          
          

         if !doc_string.index('<b>Radiologist Comments</b>').blank? 
           start_index = doc_string.index("<b>Radiologist Comments</b>")-2
         else
           start_index = doc_string.index("<h4>Radiologist Comments</h4>")-2  
         end
       
         if !doc_string.index('<form name="modReview"').blank? 
            end_index =doc_string.index('<form name="modReview"')+3
         elsif !doc_string.index('You must be logged in to submit or modify a review').blank?
            end_index	=doc_string.index("You must be logged in to submit or modify a review")+3
        else    
            end_index	=doc_string.index("If this scan has been updated:")+3
         end
         doc_string = doc_string.gsub("'","''")
         doc_header_string = doc_string[header_start_index..header_end_index]
         doc_sub_string = doc_string[start_index..end_index]
         # some pages have slight difference in start index - leaving a ">"
        doc_sub_string = doc_sub_string.gsub('> <br/> <b>Radiologist Comments',' <br/> <b>Radiologist Comments')
        doc_sub_string = doc_sub_string.gsub('> <br/> <h4>Radiologist Comments</h4','<b>Radiologist Comments</b>')
        doc_sub_string = doc_sub_string.gsub('iv> <br/> <h4>Radiologist Comments</','<b>Radiologist Comments</b>')
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
            results = connection.execute(sql)         
                               
          end                
        end 

  end

  def load_text   # THIS HAS BEEN MOVED TO MODEL!!!!!!!!!!

    sql = "select id,comment_html_1,comment_html_2,comment_html_3,comment_html_4,comment_html_5
            from radiology_comments where comment_html_1 is not null and comment_text_1 is null"
            connection = ActiveRecord::Base.connection();
            results = connection.execute(sql)
            @results = RadiologyComment.find_by_sql(sql)
                  
          @results.each do |row|
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
             var = var.gsub('<br/>','\n')
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
              
              var.gsub!('\n',"\n")
                   
             var = var.gsub("'","''")
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
             
              sql_update = sql = "update radiology_comments set comment_text_1 = '"+comment_text_1+
              "',comment_text_2 = '"+comment_text_2+"', comment_text_3 = '"+comment_text_3+"',
               comment_text_4 = '"+comment_text_4+"',  comment_text_5 = '"+comment_text_5+"',
                 q1_flag ='"+v_q1_flag+"'  
                     where radiology_comments.id = "+row.id.to_s
                     
  # puts "====="+sql_update               
                     
              connection = ActiveRecord::Base.connection();
            results = connection.execute(sql_update)
                     
          end  
            
     
  end
=end  

  
end
