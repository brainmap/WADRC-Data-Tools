# encoding: utf-8
class LookupRefsController < ApplicationController
  # GET /lookup_refs
  # GET /lookup_refs.xml
  def index
  # want most recent at top
  @lookup_refs = LookupRef.order("label,display_order,id DESC" ).all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lookup_refs }
    end
  end

  # GET /lookup_refs/1
  # GET /lookup_refs/1.xml
  def show
    @lookup_ref = LookupRef.find(params[:id])

    sql = "select distinct sp.codename, qf.description
                 from lookup_refs lr, scan_procedures sp, questions q, question_scan_procedures qsp, 
                        questionform_questions qfq ,
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( lr.label = q.ref_table_b_1 or lr.label = q.ref_table_b_2 or lr.label = q.ref_table_b_3)
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"
    connection = ActiveRecord::Base.connection();
    @sp_qf = []
    @results = connection.execute(sql)
    @results.each do |r|
         @sp_qf.push(r[1]+"</td><td>"+r[0])
    end

        sql = "select distinct sp.codename, qf.description, e.enumber
                 from lookup_refs lr, scan_procedures sp,  questions q, question_scan_procedures qsp, 
                       enrollments e, q_data qd, q_data_forms qdf,
                        questionform_questions qfq , appointments a, enrollment_vgroup_memberships evgm,
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( ( lr.label = q.ref_table_b_1 and qd.value_1)
                                 or (lr.label = q.ref_table_b_2 and qd.value_2)
                                 or (lr.label = q.ref_table_b_3 and qd.value_3) )
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and qd.question_id = q.id 
                        and qd.q_data_form_id = qdf.id
                        and  qd.value_link = a.id 
                        and q.value_link = 'appointment'
                        and a.vgroup_id =  evgm.vgroup_id
                        and evgm.enrollment_id = e.id
                        and qd.q_data_form_id = qdf.id
                        and qdf.questionform_id = qf.id
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"

    @sp_qf_enum = []
    @results = connection.execute(sql)
    @results.each do |r|
         @sp_qf_enum.push(r[1]+"</td><td>"+r[0]+"</td><td>"+r[2])
    end

        sql = "select distinct sp.codename, qf.description, e.enumber
                 from lookup_refs lr, scan_procedures sp,  questions q, question_scan_procedures qsp, 
                       enrollments e, q_data qd, q_data_forms qdf,
                        questionform_questions qfq , 
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( ( lr.label = q.ref_table_b_1 and qd.value_1)
                                 or (lr.label = q.ref_table_b_2 and qd.value_2)
                                 or (lr.label = q.ref_table_b_3 and qd.value_3) )
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and qd.question_id = q.id 
                        and qd.q_data_form_id = qdf.id
                        and  qd.value_link = e.participant_id
                        and q.value_link = 'participant'
                        and qd.q_data_form_id = qdf.id
                        and qdf.questionform_id = qf.id
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"
    @results = connection.execute(sql)
    @results.each do |r|
       @sp_qf_enum.push(r[1]+"</td><td>"+r[0]+"</td><td>"+r[2])
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lookup_ref }
    end
  end

  # GET /lookup_refs/new
  # GET /lookup_refs/new.xml
  def new
    @lookup_ref = LookupRef.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lookup_ref }
    end
  end

  # GET /lookup_refs/1/edit
  def edit
    @lookup_ref = LookupRef.find(params[:id])
    # check if ref_value in database

    sql = "select distinct sp.codename, qf.description
                 from lookup_refs lr, scan_procedures sp, questions q, question_scan_procedures qsp, 
                        questionform_questions qfq ,
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( lr.label = q.ref_table_b_1 or lr.label = q.ref_table_b_2 or lr.label = q.ref_table_b_3)
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"
    connection = ActiveRecord::Base.connection();
    @sp_qf = []
    @results = connection.execute(sql)
    @results.each do |r|
         @sp_qf.push(r[1]+"</td><td>"+r[0])
    end

        sql = "select distinct sp.codename, qf.description, e.enumber
                 from lookup_refs lr, scan_procedures sp,  questions q, question_scan_procedures qsp, 
                       enrollments e, q_data qd, q_data_forms qdf,
                        questionform_questions qfq , appointments a, enrollment_vgroup_memberships evgm,
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( ( lr.label = q.ref_table_b_1 and qd.value_1)
                                 or (lr.label = q.ref_table_b_2 and qd.value_2)
                                 or (lr.label = q.ref_table_b_3 and qd.value_3) )
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and qd.question_id = q.id 
                        and qd.q_data_form_id = qdf.id
                        and  qd.value_link = a.id 
                        and q.value_link = 'appointment'
                        and a.vgroup_id =  evgm.vgroup_id
                        and evgm.enrollment_id = e.id
                        and qd.q_data_form_id = qdf.id
                        and qdf.questionform_id = qf.id
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"

    @sp_qf_enum = []
    @results = connection.execute(sql)
    @results.each do |r|
         @sp_qf_enum.push(r[1]+"</td><td>"+r[0]+"</td><td>"+r[2])
    end

        sql = "select distinct sp.codename, qf.description, e.enumber
                 from lookup_refs lr, scan_procedures sp,  questions q, question_scan_procedures qsp, 
                       enrollments e, q_data qd, q_data_forms qdf,
                        questionform_questions qfq , 
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( ( lr.label = q.ref_table_b_1 and qd.value_1)
                                 or (lr.label = q.ref_table_b_2 and qd.value_2)
                                 or (lr.label = q.ref_table_b_3 and qd.value_3) )
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and qd.question_id = q.id 
                        and qd.q_data_form_id = qdf.id
                        and  qd.value_link = e.participant_id
                        and q.value_link = 'participant'
                        and qd.q_data_form_id = qdf.id
                        and qdf.questionform_id = qf.id
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"
    @results = connection.execute(sql)
    @results.each do |r|
       @sp_qf_enum.push(r[1]+"</td><td>"+r[0]+"</td><td>"+r[2])
    end
  end

  # POST /lookup_refs
  # POST /lookup_refs.xml
  def create
    flash[:notice]  = ""
    if params[:lookup_ref][:ref_value].to_s.strip.empty?
       flash[:notice]  = flash[:notice]  +" The ref_value cannot be empty/"
    end
    if (params[:lookup_ref][:label]).strip.empty?
       flash[:notice]  = flash[:notice]  +" The label cannot be empty/"
    end
    if (params[:lookup_ref][:description]).strip.empty?
       flash[:notice]  = flash[:notice]  +" The description cannot be empty/"
    end
    # check if already there
    v_lookup_refs = LookupRef.where(" label in (?) and ref_value in (?)",(params[:lookup_ref][:label]).strip, params[:lookup_ref][:ref_value].to_s.strip)
    if !v_lookup_refs.empty?
         flash[:notice]  = flash[:notice]  +"The label ["+params[:lookup_ref][:label] +"] and ref_value ["+params[:lookup_ref][:ref_value]+"] already exist."
    end
    @lookup_ref = LookupRef.new(params[:lookup_ref])


    respond_to do |format|
      if  v_lookup_refs.empty? and @lookup_ref.save and !(@lookup_ref.label).strip.empty? and !@lookup_ref.ref_value.to_s.empty? and !(@lookup_ref.description).strip.empty?
        @lookup_ref.label = (@lookup_ref.label).strip
        @lookup_ref.save
        format.html { redirect_to(@lookup_ref, :notice => 'Lookup ref was successfully created.') }
        format.xml  { render :xml => @lookup_ref, :status => :created, :location => @lookup_ref }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lookup_ref.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lookup_refs/1
  # PUT /lookup_refs/1.xml
  def update
    @lookup_ref = LookupRef.find(params[:id])
# NOT LETTING CHANGE OF LABEL OR REF_VALUE
sql = "select distinct sp.codename, qf.description
                 from lookup_refs lr, scan_procedures sp, questions q, question_scan_procedures qsp, 
                        questionform_questions qfq ,
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( lr.label = q.ref_table_b_1 or lr.label = q.ref_table_b_2 or lr.label = q.ref_table_b_3)
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"
    connection = ActiveRecord::Base.connection();
    @sp_qf = []
    @results = connection.execute(sql)
    @results.each do |r|
         @sp_qf.push(r[1]+"</td><td>"+r[0])
    end

        sql = "select distinct sp.codename, qf.description, e.enumber
                 from lookup_refs lr, scan_procedures sp,  questions q, question_scan_procedures qsp, 
                       enrollments e, q_data qd, q_data_forms qdf,
                        questionform_questions qfq , appointments a, enrollment_vgroup_memberships evgm,
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( ( lr.label = q.ref_table_b_1 and qd.value_1)
                                 or (lr.label = q.ref_table_b_2 and qd.value_2)
                                 or (lr.label = q.ref_table_b_3 and qd.value_3) )
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and qd.question_id = q.id 
                        and qd.q_data_form_id = qdf.id
                        and  qd.value_link = a.id 
                        and q.value_link = 'appointment'
                        and a.vgroup_id =  evgm.vgroup_id
                        and evgm.enrollment_id = e.id
                        and qd.q_data_form_id = qdf.id
                        and qdf.questionform_id = qf.id
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"

    @sp_qf_enum = []
    @results = connection.execute(sql)
    @results.each do |r|
         @sp_qf_enum.push(r[1]+"</td><td>"+r[0]+"</td><td>"+r[2])
    end

        sql = "select distinct sp.codename, qf.description, e.enumber
                 from lookup_refs lr, scan_procedures sp,  questions q, question_scan_procedures qsp, 
                       enrollments e, q_data qd, q_data_forms qdf,
                        questionform_questions qfq , 
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( ( lr.label = q.ref_table_b_1 and qd.value_1)
                                 or (lr.label = q.ref_table_b_2 and qd.value_2)
                                 or (lr.label = q.ref_table_b_3 and qd.value_3) )
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and qd.question_id = q.id 
                        and qd.q_data_form_id = qdf.id
                        and  qd.value_link = e.participant_id
                        and q.value_link = 'participant'
                        and qd.q_data_form_id = qdf.id
                        and qdf.questionform_id = qf.id
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"
    @results = connection.execute(sql)
    @results.each do |r|
       @sp_qf_enum.push(r[1]+"</td><td>"+r[0]+"</td><td>"+r[2])
    end
flash[:notice]  = ""
if (params[:lookup_ref][:label]).strip != @lookup_ref.label
     flash[:notice] = flash[:notice] +" The label can not be changed. "
end
if params[:lookup_ref][:ref_value] != @lookup_ref.ref_value.to_s
    flash[:notice] = flash[:notice] +" The ref_value can not be changed. "
end


    respond_to do |format|
      if ( current_user.role == 'Admin_High' and !(params[:lookup_ref][:label]).strip.empty?  and !(params[:lookup_ref][:ref_value]).empty?  and !(params[:lookup_ref][:description]).strip.empty?  and (params[:lookup_ref][:label]).strip == @lookup_ref.label   and params[:lookup_ref][:ref_value] == @lookup_ref.ref_value.to_s and @lookup_ref.update_attributes(params[:lookup_ref]) )
        @lookup_ref.label = (@lookup_ref.label).strip
        @lookup_ref.save
        format.html { redirect_to(@lookup_ref, :notice => 'Lookup ref was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lookup_ref.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lookup_refs/1
  # DELETE /lookup_refs/1.xml
  def destroy
    # check if ref_value in database
    @lookup_ref = LookupRef.find(params[:id])
    connection = ActiveRecord::Base.connection();

        sql = "select distinct sp.codename, qf.description, e.enumber
                 from lookup_refs lr, scan_procedures sp,  questions q, question_scan_procedures qsp, 
                       enrollments e, q_data qd, q_data_forms qdf,
                        questionform_questions qfq , appointments a, enrollment_vgroup_memberships evgm,
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( ( lr.label = q.ref_table_b_1 and qd.value_1)
                                 or (lr.label = q.ref_table_b_2 and qd.value_2)
                                 or (lr.label = q.ref_table_b_3 and qd.value_3) )
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and qd.question_id = q.id 
                        and qd.q_data_form_id = qdf.id
                        and  qd.value_link = a.id 
                        and q.value_link = 'appointment'
                        and a.vgroup_id =  evgm.vgroup_id
                        and evgm.enrollment_id = e.id
                        and qd.q_data_form_id = qdf.id
                        and qdf.questionform_id = qf.id
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"

    @sp_qf_enum = []
    @results = connection.execute(sql)
    @results.each do |r|
         @sp_qf_enum.push(r[1]+"</td><td>"+r[0]+"</td><td>"+r[2])
    end

        sql = "select distinct sp.codename, qf.description, e.enumber
                 from lookup_refs lr, scan_procedures sp,  questions q, question_scan_procedures qsp, 
                       enrollments e, q_data qd, q_data_forms qdf,
                        questionform_questions qfq , 
                          questionforms qf 
                              LEFT JOIN questionformnamesps  qfsp on qfsp.questionform_id = qf.id
                        where ( ( lr.label = q.ref_table_b_1 and qd.value_1)
                                 or (lr.label = q.ref_table_b_2 and qd.value_2)
                                 or (lr.label = q.ref_table_b_3 and qd.value_3) )
                        and q.id = qsp.question_id
                        and qsp.scan_procedure_id = sp.id
                        and q.id = qfq.question_id 
                        and qfq.questionform_id = qf.id 
                        and qd.question_id = q.id 
                        and qd.q_data_form_id = qdf.id
                        and  qd.value_link = e.participant_id
                        and q.value_link = 'participant'
                        and qd.q_data_form_id = qdf.id
                        and qdf.questionform_id = qf.id
                        and lr.id = "+params[:id]+" order by qf.description,sp.codename"
    @results = connection.execute(sql)
    @results.each do |r|
       @sp_qf_enum.push(r[1]+"</td><td>"+r[0]+"</td><td>"+r[2])
    end
    flash[:notice]  = ""
    if @sp_qf_enum.count > 0
        flash[:notice] = flash[:notice] + " The value could not be deleted. There are records in the database referencing the value."
    end
    if current_user.role == 'Admin_High' and @sp_qf_enum.count == 0
      @lookup_ref.destroy
    end
    respond_to do |format|
      format.html { redirect_to(lookup_refs_url) }
      format.xml  { head :ok }
    end
  end
end
