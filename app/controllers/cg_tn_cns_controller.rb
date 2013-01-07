class CgTnCnsController < ApplicationController
  # GET /cg_tn_cns
  # GET /cg_tn_cns.xml
  def index
    @cg_tn_cns = CgTnCn.find(:all, :order =>"cg_tn_id,display_order")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cg_tn_cns }
    end
  end

  # GET /cg_tn_cns/1
  # GET /cg_tn_cns/1.xml
  def show
    @cg_tn_cn = CgTnCn.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cg_tn_cn }
    end
  end

  # GET /cg_tn_cns/new
  # GET /cg_tn_cns/new.xml
  def new
    @cg_tn_cn = CgTnCn.new
   @load_next_column = "N"
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cg_tn_cn }
    end
  end

  # GET /cg_tn_cns/1/edit
  def edit
    @cg_tn_cn = CgTnCn.find(params[:id])
    if !params[:load_next_column].blank?
        @load_next_column = params[:load_next_column]
    else
       @load_next_column = "N"
    end
  end
  


  # POST /cg_tn_cns
  # POST /cg_tn_cns.xml
  def create
    if params[:cg_tn_cn][:display_order].blank?
      params[:cg_tn_cn][:display_order] = "0"
    end
    @cg_tn_cn = CgTnCn.new(params[:cg_tn_cn])
    @load_next_column = ""
    if !params[:load_next_column].blank?
      @load_next_column = params[:load_next_column]
    end 

    respond_to do |format|
      if @cg_tn_cn.save
        if !@load_next_column.blank? and @load_next_column == "Y"
          # get the next column_name
          cg_tn = CgTn.find(params[:cg_tn_cn][:cg_tn_id]) 
          sql = "SHOW COLUMNS FROM "+cg_tn.tn
          connection = ActiveRecord::Base.connection();
          @results = connection.execute(sql)
          v_next_column =""
          v_next_column_datatype =""
          v_get_next_column = "N"
          @results.each do |r|
            if v_get_next_column == "Y"
              v_get_next_column = "N"
              v_next_column = r[0]
              v_next_column_datatype = r[1]
            end
            if r[0] == params[:cg_tn_cn][:cn]
              v_get_next_column = "Y"
            end
          end
          if v_next_column == ""
            format.html { redirect_to(@cg_tn_cn, :notice => 'Cg tn cn was successfully created.') }
          else
            @cg_tn_cn = CgTnCn.new
            @cg_tn_cn.cn = v_next_column
            @cg_tn_cn.common_name = v_next_column
            @cg_tn_cn.export_name = v_next_column
            if v_next_column_datatype == "date"
              @cg_tn_cn.data_type ="date"
            elsif v_next_column_datatype.include?('int')
              @cg_tn_cn.data_type ="integer"
            elsif v_next_column_datatype == "float"
               @cg_tn_cn.data_type ="float"
            elsif v_next_column_datatype.include?('varchar')
               @cg_tn_cn.data_type ="string"
            elsif v_next_column_datatype.include?('char')
               @cg_tn_cn.data_type ="string"
            end
            @cg_tn_cn.cg_tn_id = params[:cg_tn_cn][:cg_tn_id]
            @cg_tn_cn.display_order = (params[:cg_tn_cn][:display_order]).to_i + 1
            format.html { render :action => "new" }
          end
        else
          format.html { redirect_to(@cg_tn_cn, :notice => 'Cg tn cn was successfully created.') }
        end
        format.xml  { render :xml => @cg_tn_cn, :status => :created, :location => @cg_tn_cn }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cg_tn_cn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cg_tn_cns/1
  # PUT /cg_tn_cns/1.xml
  def update
    @cg_tn_cn = CgTnCn.find(params[:id])
    @load_next_column = ""
    if !params[:load_next_column].blank?
      @load_next_column = params[:load_next_column]
    end
    if params[:cg_tn_cn][:display_order].blank?
      params[:cg_tn_cn][:display_order] = 0
    end
    respond_to do |format|
      if @cg_tn_cn.update_attributes(params[:cg_tn_cn])
        if !@load_next_column.blank? and @load_next_column == "Y"
          # get the next column_name
          cg_tn = CgTn.find(params[:cg_tn_cn][:cg_tn_id]) 
          sql = "SHOW COLUMNS FROM "+cg_tn.tn
          connection = ActiveRecord::Base.connection();
          @results = connection.execute(sql)
          v_next_column =""
          v_next_column_datatype =""
          v_get_next_column = "N"
          @results.each do |r|
            if v_get_next_column == "Y"
              v_get_next_column = "N"
              v_next_column = r[0]
              v_next_column_datatype = r[1]
            end
            if r[0] == params[:cg_tn_cn][:cn]
              v_get_next_column = "Y"
            end
          end

          @cg_tn_cn = CgTnCn.new
          @cg_tn_cn.cn = v_next_column
          @cg_tn_cn.common_name = v_next_column
          @cg_tn_cn.export_name = v_next_column
          if v_next_column_datatype == "date"
            @cg_tn_cn.data_type ="date"
          elsif v_next_column_datatype.include?('int')
            @cg_tn_cn.data_type ="integer"
          elsif v_next_column_datatype == "float"
             @cg_tn_cn.data_type ="float"
          elsif v_next_column_datatype.include?('varchar')
             @cg_tn_cn.data_type ="string"
          elsif v_next_column_datatype.include?('char')
             @cg_tn_cn.data_type ="string"
          end
          @cg_tn_cn.cg_tn_id = params[:cg_tn_cn][:cg_tn_id]
          @cg_tn_cn.display_order = (params[:cg_tn_cn][:display_order]).to_i + 1
          format.html { render :action => "new" }
        else
          format.html { redirect_to(@cg_tn_cn, :notice => 'Cg tn cn was successfully updated.') }
        end
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cg_tn_cn.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cg_tn_cns/1
  # DELETE /cg_tn_cns/1.xml
  def destroy
    @cg_tn_cn = CgTnCn.find(params[:id])
    @cg_tn_cn.destroy

    respond_to do |format|
      format.html { redirect_to(cg_tn_cns_url) }
      format.xml  { head :ok }
    end
  end
end
