# encoding: utf-8
class CgTnCnsController < ApplicationController
  # GET /cg_tn_cns
  # GET /cg_tn_cns.xml
  def index
    @cg_tn_cns = CgTnCn.all.order("cg_tn_id DESC,display_order ASC")
    @cg_tns = CgTn.order("common_name")

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
   @load_all_rest_columns = "N"
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
        @load_all_rest_columns = params[:load_all_rest_columns]
    else
       @load_next_column = "N"
       @load_all_rest_columns = "N"
    end
  end
  
  # batch update column orde rand other properties
  def tn_cols
    puts "AAAAAAA id="+params[:id]
    @cg_tn = CgTn.find(params[:id])
    
    if !params[:tn_cn_id].blank?
      params[:tn_cn_id].each do |cn|
         puts "aaaaaa cn id="+cn
         @cg_tn_cn = CgTnCn.find(cn)
         @cg_tn_cn.display_order = params[:display_order][cn]
         @cg_tn_cn.status_flag = params[:status_flag][cn]
         @cg_tn_cn.common_name = params[:common_name][cn]
         @cg_tn_cn.export_name = params[:export_name][cn]  
         @cg_tn_cn.save
      end
    end
        @cg_tn_cns = CgTnCn.where("cg_tn_id = "+params[:id]).all.order("display_order ASC") #  find(:all,:order=>"display_order")
    respond_to do |format|
      format.html 
      format.xml  { head :ok }
    end
  end

  # POST /cg_tn_cns
  # POST /cg_tn_cns.xml
  def create
    if params[:cg_tn_cn][:display_order].blank?
      params[:cg_tn_cn][:display_order] = "0"
    end
    @cg_tn_cn = CgTnCn.new(cg_tn_cn_params)#params[:cg_tn_cn])
    @load_next_column = ""
    @load_all_rest_columns = ""
    if !params[:load_next_column].blank?
      @load_next_column = params[:load_next_column]
      @load_all_rest_columns = params[:load_all_rest_columns]
    end 

    respond_to do |format|
      if @cg_tn_cn.save
        if !@load_all_rest_columns.blank? and @load_all_rest_columns == "Y"
          # go until the last cg_tn_cn - save current and then loop
          # get the next column_name
          cg_tn = CgTn.find(params[:cg_tn_cn][:cg_tn_id]) 
          sql = "SHOW COLUMNS FROM "+cg_tn.tn
          connection = ActiveRecord::Base.connection();
          @results = connection.execute(sql)
          v_next_column =""
          v_next_column_datatype =""
          v_get_next_column = "N"
          @results.each do |r|
            v_next_column =""
            v_next_column_datatype =""
            if v_get_next_column == "Y"
              v_get_next_column = "N"
              v_next_column = r[0]
              v_next_column_datatype = r[1]
              @cg_tn_cn_next = CgTnCn.new
              @cg_tn_cn_next.cn = v_next_column
              @cg_tn_cn_next.common_name = v_next_column
              @cg_tn_cn_next.export_name = v_next_column
              if v_next_column_datatype == "date"
                @cg_tn_cn_next.data_type ="date"
              elsif v_next_column_datatype.include?('int')
                @cg_tn_cn_next.data_type ="integer"
              elsif v_next_column_datatype == "float"
                @cg_tn_cn_next.data_type ="float"
              elsif v_next_column_datatype.include?('varchar')
                @cg_tn_cn_next.data_type ="string"
              elsif v_next_column_datatype.include?('char')
                @cg_tn_cn_next.data_type ="string"
              end
              @cg_tn_cn_next.cg_tn_id = params[:cg_tn_cn][:cg_tn_id]
              @cg_tn_cn_next.display_order = (params[:cg_tn_cn][:display_order]).to_i + 1
              params[:cg_tn_cn][:display_order] = @cg_tn_cn_next.display_order
              params[:cg_tn_cn][:cn] = @cg_tn_cn_next.cn
              @cg_tn_cn_next.save
            end
            if r[0] == params[:cg_tn_cn][:cn]
              v_get_next_column = "Y"
              v_next_column = "check_for_next"
            end 
          end





        elsif !@load_next_column.blank? and @load_next_column == "Y"
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
        end
        if !@cg_tn_cn_next.nil? and !(@cg_tn_cn_next.cn).nil?
          format.html { redirect_to(@cg_tn_cn_next, :notice => 'Cg tn cn was successfully created - ALL rest of columns loaded.') }
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
      if @cg_tn_cn.update(cg_tn_cn_params)#params[:cg_tn_cn], :without_protection => true)
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
  private
    def set_cg_tn_cn
       @cg_tn_cn = CgTnCn.find(params[:id])
    end
   def cg_tn_cn_params
          # ALSO ADD ANY NEW FIELDS TO THE data_searches_controller   cg_snapshot -- 
          params.require(:cg_tn_cn).permit(:secondary_key_visitno_flag,:display_order,:created_at,:data_type,:ref_table_b,:ref_table_a,:key_column_flag,:export_name,:common_name,:cn,:cg_tn_id,:searchable_flag,:value_limits,:secondary_key_protocol_flag,:match_mri_path_flag,:hide_column_flag,:order_by_flag,:description,:q_data_form_id,:value_list,:condition_between_flag,:status_flag,:updated_at,:id,:dashboard_edit_flag,:exclude_from_char_replacement_flag)
   end
end
