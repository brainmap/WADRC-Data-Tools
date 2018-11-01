class FoldersController < ApplicationController
  before_action :set_folder, only: [:show, :edit, :update, :destroy]

  # GET /folders
  # GET /folders.json
  def index
    @folders = Folder.all
  end

  # GET /folders/1
  # GET /folders/1.json
  def show
  end

  # GET /folders/new
  def new
    @folder = Folder.new
  end

  # GET /folders/1/edit
  def edit
  end

  # POST /folders
  # POST /folders.json
  def create
    @folder = Folder.new(folder_params)

    respond_to do |format|
      if @folder.save
        format.html { redirect_to @folder, notice: 'Folder was successfully created.' }
        format.json { render :show, status: :created, location: @folder }
      else
        format.html { render :new }
        format.json { render json: @folder.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /folders/1
  # PATCH/PUT /folders/1.json
  def update
    respond_to do |format|
      if @folder.update(folder_params)
        format.html { redirect_to @folder, notice: 'Folder was successfully updated.' }
        format.json { render :show, status: :ok, location: @folder }
      else
        format.html { render :edit }
        format.json { render json: @folder.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /folders/1
  # DELETE /folders/1.json
  def destroy
    @folder.destroy
    respond_to do |format|
      format.html { redirect_to folders_url, notice: 'Folder was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  def collect_folder_actual_permissions
     v_computer = "merida"
     v_user ="panda_user" # won't be able to go some places
     @folders = Folder.all.where("folders.parent_id in ( select id from folders)")
     @folders.each do |folder|
         # getfacl from system over ssh - the user names/id different between brainapps and rest of machines
         # if have success in getting perms, delete existing folderpermissions
         # insert new folderpermissions

         v_call = "ssh "+v_user+"@"+v_computer+".dom.wisc.edu 'getfacl "+folder.folder_path+"' "
        puts "aaaaa="+v_call    
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          puts stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close


     end

  end

  def folder_home
    #####self.collect_folder_actual_permissions
     @v_next_one_hash = Hash.new
     @v_next_two_hash = Hash.new
     @v_next_three_hash = Hash.new
     @v_next_four_hash = Hash.new
     @v_next_five_hash = Hash.new
     @v_next_one_count_hash = Hash.new
     @v_next_two_count_hash = Hash.new
     @v_next_three_count_hash = Hash.new
     @v_next_four_count_hash = Hash.new
     @v_next_five_count_hash = Hash.new
     @v_top_count_hash = Hash.new

     @top_folder = Folder.where("folders.parent_id not in ( select id from folders)")
     @top_folder.each do |top|
       @v_top_count_hash[top.id] = 1
       @next_one_folder = Folder.where("parent_id in (?)",top.id)
       if !@next_one_folder.nil?
          @v_next_one_hash[top.id] = @next_one_folder
          @v_next_one_count_hash[top.id] = @next_one_folder.count
          @v_top_count_hash[top.id] = @next_one_folder.count
          @next_one_folder.each do |nextfol_one|   
             @next_two_folder = Folder.where("parent_id in (?)",nextfol_one.id)
             if !@next_two_folder.nil? and @next_two_folder.count > 0
                 @v_next_two_hash[nextfol_one.id] = @next_two_folder
                 @v_next_two_count_hash[nextfol_one.id] = @next_two_folder.count
                 @v_top_count_hash[top.id] = @next_two_folder.count
                 @next_two_folder.each do |nextfol_two|   
                   @next_three_folder = Folder.where("parent_id in (?)",nextfol_two.id)
                   if !@next_three_folder.nil? and @next_three_folder.count > 0
                     @v_next_three_hash[nextfol_two.id] = @next_three_folder
                     @v_next_three_count_hash[nextfol_two.id] = @next_three_folder.count
                     @v_top_count_hash[top.id] = @next_three_folder.count
                     @next_three_folder.each do |nextfol_three|   
                       @next_four_folder = Folder.where("parent_id in (?)",nextfol_three.id)
                       if !@next_four_folder.nil? and @next_four_folder.count > 0
                         @v_next_four_hash[nextfol_three.id] = @next_four_folder
                         @v_next_four_count_hash[nextfol_three.id] = @next_four_folder.count
                         @v_top_count_hash[top.id] = @next_four_folder.count
                         @next_four_folder.each do |nextfol_four|   
                           @next_five_folder = Folder.where("parent_id in (?)",nextfol_four.id)
                           if !@next_five_folder.nil? and @next_five_folder.count > 0
                             @v_next_five_hash[nextfol_four.id] = @next_five_folder
                             @v_next_five_count_hash[nextfol_four.id] = @next_five_folder.count
                             @v_top_count_hash[top.id] = @next_five_folder.count
                           end # five not nil      
                         end # loop four
                       end # four not nil         
                     end # loop three
                   end # three not nil    
                 end # two loop
             end # two not nil
          end # loop one
       end # one not nil
     end # loop top

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_folder
      @folder = Folder.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def folder_params
      params.require(:folder).permit(:folder_path, :child_path, :permission_s_flag, :parent_id)
    end
end
