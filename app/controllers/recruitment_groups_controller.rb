class RecruitmentGroupsController < ApplicationController
  # GET /recruitment_groups
  # GET /recruitment_groups.xml
  def index
    @recruitment_groups = RecruitmentGroup.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @recruitment_groups }
    end
  end

  # GET /recruitment_groups/1
  # GET /recruitment_groups/1.xml
  def show
    @recruitment_group = RecruitmentGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @recruitment_group }
    end
  end

  # GET /recruitment_groups/new
  # GET /recruitment_groups/new.xml
  def new
    @recruitment_group = RecruitmentGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @recruitment_group }
    end
  end

  # GET /recruitment_groups/1/edit
  def edit
    @recruitment_group = RecruitmentGroup.find(params[:id])
  end

  # POST /recruitment_groups
  # POST /recruitment_groups.xml
  def create
    @recruitment_group = RecruitmentGroup.new(params[:recruitment_group])

    respond_to do |format|
      if @recruitment_group.save
        flash[:notice] = 'RecruitmentGroup was successfully created.'
        format.html { redirect_to(@recruitment_group) }
        format.xml  { render :xml => @recruitment_group, :status => :created, :location => @recruitment_group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @recruitment_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /recruitment_groups/1
  # PUT /recruitment_groups/1.xml
  def update
    @recruitment_group = RecruitmentGroup.find(params[:id])

    respond_to do |format|
      if @recruitment_group.update_attributes(params[:recruitment_group])
        flash[:notice] = 'RecruitmentGroup was successfully updated.'
        format.html { redirect_to(@recruitment_group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @recruitment_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /recruitment_groups/1
  # DELETE /recruitment_groups/1.xml
  def destroy
    @recruitment_group = RecruitmentGroup.find(params[:id])
    @recruitment_group.destroy

    respond_to do |format|
      format.html { redirect_to(recruitment_groups_url) }
      format.xml  { head :ok }
    end
  end
end
