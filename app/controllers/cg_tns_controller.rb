# encoding: utf-8
class CgTnsController < ApplicationController
  # GET /cg_tns
  # GET /cg_tns.xml
  def index
    @cg_tns = CgTn.all
    if !params[:search].nil? 
         if !params[:search][:table_type].blank? 
            @cg_tns = CgTn.where("cg_tns.table_type in (?)",params[:search][:table_type])
         end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cg_tns }
    end
  end

  # GET /cg_tns/1
  # GET /cg_tns/1.xml
  def show
    @cg_tn = CgTn.find(params[:id])
    v_app_base_path = Rails.root
    v_datadictionary_base = v_app_base_path.to_s+"/public/system/datadictionaries/"
    if Rails.env=="production"  # problems with umask and permission
          v_datadictionary_base  = v_app_base_path.to_s+"/shared/system/datadictionaries/"
    end
    v_datadictionary_path = v_datadictionary_base+params[:id].to_s
    puts "aaaaaaaaaaaa v_datadictionary_path=  "+v_datadictionary_path
                    # problem with umask 007 setting all files to 770 , and files created as non-expected (web server?) user
                    # FileUtils.chown_R('panda_user','panda_group', v_thumbnail_path); 
                     # check if file exists,
                     # check permissions 
    if File.directory?(v_datadictionary_path)
        FileUtils.chmod_R(0774, v_datadictionary_path)
    end 

    v_datadictionary_base = v_app_base_path.to_s+"/public/system/datadictionary2s/"
    if Rails.env=="production"  # problems with umask and permission
          v_datadictionary_base  = v_app_base_path.to_s+"/shared/system/datadictionary2s/"
    end
    v_datadictionary_path = v_datadictionary_base+params[:id].to_s
    puts "aaaaaaaaaaaa v_datadictionary_path=  "+v_datadictionary_path
                    # problem with umask 007 setting all files to 770 , and files created as non-expected (web server?) user
                    # FileUtils.chown_R('panda_user','panda_group', v_thumbnail_path); 
                     # check if file exists,
                     # check permissions 
    if File.directory?(v_datadictionary_path)
        FileUtils.chmod_R(0774, v_datadictionary_path)
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cg_tn }
    end
  end

  # GET /cg_tns/new
  # GET /cg_tns/new.xml
  def new
    @cg_tn = CgTn.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cg_tn }
    end
  end

  # GET /cg_tns/1/edit
  def edit
    @cg_tn = CgTn.find(params[:id])
  end
  
 
  
  def create_from_cg_tn_db
    
    params[:cg_tn][:tn] =  params[:cg_table_name].downcase
    v_tn = params[:cg_table_name].downcase 
    params[:cg_tn][:common_name] = params[:cg_table_name]
    params[:cg_tn][:editable_flag] ="Y"
    params[:cg_tn][:status_flag] ="Y"
    params[:cg_tn][:table_type] ="column_group"
    sql = "select max(display_order) from cg_tns where table_type ='column_group'"
    connection = ActiveRecord::Base.connection();
    @results = connection.execute(sql)
    v_display_order = (@results.first.to_s.to_i)+1
    params[:cg_tn][:display_order] = v_display_order.to_s
    if params[:key_type] == 'enrollment/sp'
      params[:cg_tn][:join_left_parent_tn] ="vgroups"
      params[:cg_tn][:join_left] ="LEFT JOIN "+v_tn+" on vgroups.id in ( select spv2.vgroup_id from scan_procedures_vgroups spv2 where spv2.scan_procedure_id = "+v_tn+".scan_procedure_id and spv2.vgroup_id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships where enrollment_vgroup_memberships.enrollment_id = "+v_tn+".enrollment_id))"
      params[:cg_tn][:join_right] ="appointments.appointment_type is not NULL and scan_procedures_vgroups.scan_procedure_id = "+v_tn+".scan_procedure_id and vgroups.id in (select enrollment_vgroup_memberships.vgroup_id from enrollment_vgroup_memberships where enrollment_vgroup_memberships.enrollment_id = "+v_tn+".enrollment_id)"
    elsif params[:key_type] == 'participant_id'
      params[:cg_tn][:join_left_parent_tn] ="vgroups"
      params[:cg_tn][:join_left]="LEFT JOIN "+v_tn+" on vgroups.participant_id = "+v_tn+".participant_id"
      params[:cg_tn][:join_right]="vgroups.participant_id = "+v_tn+".participant_id"
    elsif params[:key_type] == 'reggieid-kc-participant_id'
      params[:cg_tn][:join_left_parent_tn] ="vgroups"
      params[:cg_tn][:join_left]="LEFT JOIN "+v_tn+" on vgroups.participant_id = "+v_tn+".participant_id"
      params[:cg_tn][:join_right]="vgroups.participant_id = "+v_tn+".participant_id"      
    elsif params[:key_type] == 'wrapnum-kc-participant_id'
      params[:cg_tn][:join_left_parent_tn] ="vgroups"
      params[:cg_tn][:join_left]="LEFT JOIN "+v_tn+" on vgroups.participant_id = "+v_tn+".participant_id"
      params[:cg_tn][:join_right]="vgroups.participant_id = "+v_tn+".participant_id"      
    elsif params[:key_type] == 'adrcnum-kc-participant_id'
      params[:cg_tn][:join_left_parent_tn] ="vgroups"
      params[:cg_tn][:join_left]="LEFT JOIN "+v_tn+" on vgroups.participant_id = "+v_tn+".participant_id"
      params[:cg_tn][:join_right]="vgroups.participant_id = "+v_tn+".participant_id"      
    end
    params[:cg_tn][:join_left_parent_tn] =  params[:cg_tn][:join_left_parent_tn].downcase
    @cg_tn = CgTn.new(params[:cg_tn])
    respond_to do |format|
      if @cg_tn.save
        format.html { redirect_to(@cg_tn, :notice => 'Cg tn was successfully created.') }
        format.xml  { render :xml => @cg_tn, :status => :created, :location => @cg_tn }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cg_tn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /cg_tns
  # POST /cg_tns.xml
  def create
    params[:cg_tn][:tn] =  params[:cg_tn][:tn].downcase 
    params[:cg_tn][:join_left_parent_tn] =  params[:cg_tn][:join_left_parent_tn].downcase
    @cg_tn = CgTn.new(cg_tn_params)# params[:cg_tn])
    v_schema ='panda_production'
    if Rails.env=="development" 
      v_schema ='panda_development'
    end
    respond_to do |format|
      if @cg_tn.save
        sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '"+v_schema+"'  AND table_name = '"+@cg_tn.tn+"'"
        connection = ActiveRecord::Base.connection();
        @results = connection.execute(sql)
        if @results.first[0] > 0 
          format.html { redirect_to(@cg_tn, :notice => 'Cg tn was successfully created.') }
        else
          format.html { redirect_to(@cg_tn, :notice => 'WARNING: THE TABLE NEEDS TO CREATED IN THE DATABASE!!!! Cg tn was successfully created in search table.') }
        end
        
        format.html { redirect_to(@cg_tn, :notice => 'Cg tn was successfully created.') }
        format.xml  { render :xml => @cg_tn, :status => :created, :location => @cg_tn }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cg_tn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cg_tns/1
  # PUT /cg_tns/1.xml
  def update
    
   # puts "aaaaaaa datadictionary = "+params[:cg_tn][:datadictionary].content_type
    @cg_tn = CgTn.find(params[:id])
     params[:cg_tn][:tn] =  params[:cg_tn][:tn].downcase 
     params[:cg_tn][:join_left_parent_tn] =  params[:cg_tn][:join_left_parent_tn].downcase
    respond_to do |format|
      if @cg_tn.update(cg_tn_params)#params[:cg_tn], :without_protection => true)
        format.html { redirect_to(@cg_tn, :notice => 'Cg tn was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cg_tn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cg_tns/1
  # DELETE /cg_tns/1.xml
  def destroy
    @cg_tn = CgTn.find(params[:id])
    @cg_tn.destroy

    respond_to do |format|
      format.html { redirect_to(cg_tns_url) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_cg_tn
       @cg_tn = CgTn.find(params[:id])
    end
   def cg_tn_params
          params.require(:cg_tn).permit(:join_left_parent_tn,:status_flag,:updated_at,:created_at,:table_type,:display_order,:join_right,:join_left,:common_name,:tn,:id,:editable_flag,:datadictionary_file_name,:datadictionary2_updates_at,:datadictionary2_file_size,:datadictionary2_content_type,:datadictionary2_file_name,:secondary_key_flag,:tracker_id,:table_group_id,:alias,:datadictionary_file_size,:datadictionary_content_type,:view_tn_participant_link,:datadictionary_updated_at,:datadictionary,:datadictionary2,:contact_owner_table,:secondary_edit_flag,user_ids: [])
   end
end
