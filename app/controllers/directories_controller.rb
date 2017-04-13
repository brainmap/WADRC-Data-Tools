class DirectoriesController < ApplicationController   
  before_action :set_directory, only: [:show, :edit, :update, :destroy]   
	respond_to :html
	# GET /directories
	# GET /directories.xml
	def index
		@directories = Directory.where("status_flag='Y'").order("position,path")
		@directories_status_n = Directory.where("status_flag='N'").order("position ASC, path ASC")
		@days = params[:days].blank? ? 31 : params[:days].to_i
		respond_to do |format|
			format.html # index.html.erb
			format.xml	{ render :xml => @directories }
		end
	end

	# GET /directories/1
	# GET /directories/1.xml
	def show
		@directory = Directory.find(params[:id])
		@days = params[:days].blank? ? 31 : params[:days].to_i		
		respond_to do |format|
			format.html # show.html.erb
			format.xml	{ render :xml => @directory }
		end
	end

	# GET /directories/new
	# GET /directories/new.xml
	def new
		@directory = Directory.new
    v_base_path = Shared.get_base_path()
    sql = "select max(position)+1 from directories"
    connection = ActiveRecord::Base.connection();
    @results = connection.execute(sql)
    @directory.position = @results.first[0]
    @directory.path = v_base_path+"/[ enter dir ]"
		respond_to do |format|
			format.html # new.html.erb
			format.xml	{ render :xml => @directory }
		end
	end

	# GET /directories/1/edit
	def edit
		@directory = Directory.find(params[:id])
	end

	# POST /directories
	# POST /directories.xml
	def create
		@directory = Directory.new(directory_params)#params[:directory])
		respond_to do |format|
			if @directory.save
				format.html { redirect_to(@directory, :notice => 'Directory was successfully created.') }
				format.xml	{ render :xml => @directory, :status => :created, :location => @directory }
			else
				format.html { render :action => "new" }
				format.xml	{ render :xml => @directory.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /directories/1
	# PUT /directories/1.xml
	def update
		@directory = Directory.find(params[:id])

		respond_to do |format|
			if @directory.update(directory_params)#params[:directory], :without_protection => true)
				format.html { redirect_to(@directory, :notice => 'Directory was successfully updated.') }
				format.xml	{ head :ok }
			else
				format.html { render :action => "edit" }
				format.xml	{ render :xml => @directory.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /directories/1
	# DELETE /directories/1.xml
	def destroy
		@directory = Directory.find(params[:id])
		@directory.status_flag = 'N'
		@directory.save

		respond_to do |format|
			format.html { redirect_to(directories_url) }
			format.xml	{ head :ok }
		end
	end
	
	# for sortable directories
	def sort
	  params[:directories].each_with_index do |id, index|
	    Directory.update_all(['position=?', index+1], ['id=?', id])
	  end
	  render :nothing => true
	end 
	
	private
    def set_directory
       @directory = Directory.find(params[:id])
    end
   def directory_params
          params.require(:directory).permit(:drill_down_flag,:position,:label,:path,:id,:status_flag)
   end
end
