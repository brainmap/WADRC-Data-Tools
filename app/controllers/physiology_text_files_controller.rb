# encoding: utf-8
class PhysiologyTextFilesController < ApplicationController
  # GET /physiology_text_files
  # GET /physiology_text_files.xml
  def index
    @physiology_text_files = PhysiologyTextFile.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @physiology_text_files }
    end
  end

  # GET /physiology_text_files/1
  # GET /physiology_text_files/1.xml
  def show
    @physiology_text_file = PhysiologyTextFile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @physiology_text_file }
    end
  end

  # GET /physiology_text_files/new
  # GET /physiology_text_files/new.xml
  def new
    @physiology_text_file = PhysiologyTextFile.new
    @physiology_text_file.file_path = File.join(File.expand_path('../', image_dataset.path), 'phys_data/')

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @physiology_text_file }
    end
  end

  # GET /physiology_text_files/1/edit
  def edit
    @physiology_text_file = PhysiologyTextFile.find(params[:id])
  end

  # POST /physiology_text_files
  # POST /physiology_text_files.xml
  def create
    @physiology_text_file = PhysiologyTextFile.new(physiology_text_file_params)# params[:physiology_text_file])

    respond_to do |format|
      if @physiology_text_file.save
        flash[:notice] = 'PhysiologyTextFile was successfully created.'
        format.html { redirect_to(@physiology_text_file) }
        format.xml  { render :xml => @physiology_text_file, :status => :created, :location => @physiology_text_file }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @physiology_text_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /physiology_text_files/1
  # PUT /physiology_text_files/1.xml
  def update
    @physiology_text_file = PhysiologyTextFile.find(params[:id])
    
    if validates_truthiness_of_directory(@visit_directory_to_scan)
      respond_to do |format|
        if @physiology_text_file.update(physiology_text_file_params)# params[:physiology_text_file], :without_protection => true)
          flash[:notice] = 'PhysiologyTextFile was successfully updated.'
          format.html { redirect_to(@physiology_text_file) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @physiology_text_file.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /physiology_text_files/1
  # DELETE /physiology_text_files/1.xml
  def destroy
    @physiology_text_file = PhysiologyTextFile.find(params[:id])
    @physiology_text_file.destroy

    respond_to do |format|
      format.html { redirect_to(physiology_text_files_url) }
      format.xml  { head :ok }
    end
  end

  def validates_truthiness_of_directory(dir)
    # dir =~ /Data\/vtrak1\/raw\//
     dir =~ /mounts\/data\/raw\//
  end   
  private
    def set_physiology_text_file
       @physiology_text_file = PhysiologyTextFile.find(params[:id])
    end
   def physiology_text_file_params
          params.require(:physiology_text_file).permit(:image_dataset_id,:filepath,:id)
   end
end
