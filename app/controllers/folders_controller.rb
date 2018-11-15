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
puts "gggggggg folder.id="+folder.id.to_s
         v_call = "ssh "+v_user+"@"+v_computer+".dom.wisc.edu 'getfacl "+folder.folder_path+"' "
        puts "aaaaa="+v_call  
        v_val = "" 
        stdin, stdout, stderr = Open3.popen3(v_call)
        while !stdout.eof?
          v_val =stdout.read 1024    
         end
        stdin.close
        stdout.close
        stderr.close
        puts v_val
        v_owner ="" ## owner:    default:user::
        v_owner_permission =""
        v_owner_group = "" ## group   default:group::
        v_owner_group_permission = ""
        v_flags = "" # flags:
        v_mask_permission = ""
        v_other_permission =""
        v_group_array = []
        v_user_array = []
        v_group_permission_hash = Hash.new
        v_user_permission_hash = Hash.new
        # default:user:<user_name>:rwx
        # default:group:<group_name>:rwx
        # default:mask::rwx    ???
        #default:other:: 
        v_row_array = v_val.split(/\n+/)
        v_row_array.each do |v_row|
          if v_row.start_with?("# owner:")
                v_owner = (v_row.split(":"))[1].gsub(/\s+/, "")
          elsif v_row.start_with?("# group:")
                v_owner_group = (v_row.split(":"))[1].gsub(/\s+/, "")
          elsif v_row.start_with?("default:user::")
                v_user_permission_hash[v_owner] = v_row.split(":")[3]
          elsif v_row.start_with?("default:group::")
                v_group_permission_hash[v_owner_group] = v_row.split(":")[3]
          elsif v_row.start_with?("mask::")
                v_mask_permission = v_row.split(":")[2]
          elsif v_row.start_with?("default:user:") and !v_row.start_with?("default:user::")
                v_tmp_array = v_row.split(":")
                v_user_array.push(v_tmp_array[2])
                v_user_permission_hash[v_tmp_array[2]] = v_tmp_array[3]
          elsif v_row.start_with?("default:group:") and !v_row.start_with?("default:group::")
                v_tmp_array = v_row.split(":")
                v_group_array.push(v_tmp_array[2])
                v_group_permission_hash[v_tmp_array[2]] = v_tmp_array[3]
          elsif v_row.start_with?("default:other::")
                v_other_permission = v_row.split(":")[3]
          elsif  v_row.start_with?("user::")
                v_owner_permission = v_row.split(":")[2]
          elsif  v_row.start_with?("group::")
                v_owner_group_permission = v_row.split(":")[2]
          end
        end
        v_user_permission_hash[v_owner] = v_owner_permission
        v_group_permission_hash[v_owner_group] = v_owner_group_permission
#NOT GETTING ALL THE PERMISSIONS - especially owner

        # save in folderpermissions
        v_user_array.each do |user|
           v_perms=v_user_permission_hash[user]
           puts "uuuuu user="+user+" "+v_perms
           v_folderpermissions = Folderpermission.where("folder_id in (?) and network_user in (?) and actual_vs_planned in (?)",folder.id,user,"actual")
           if !v_folderpermissions.nil? and v_folderpermissions.count > 0
                v_folderpermissions.each do |v_folderpermission|
                  if v_perms.include?("r")
                    v_folderpermission.permission_read ="r"
                  end
                  if v_perms.include?("w")
                    v_folderpermission.permission_write ="w"
                  end
                  if v_perms.include?("x")
                    v_folderpermission.permission_execute ="x"
                  end
                  v_folderpermission.save
                end
           else
                v_folderpermission = Folderpermission.new
                v_folderpermission.folder_id = folder.id
                v_folderpermission.actual_vs_planned = "actual"
                v_folderpermission.network_user = user
                if v_perms.include?("r")
                    v_folderpermission.permission_read ="r"
                end
                if v_perms.include?("w")
                    v_folderpermission.permission_write ="w"
                end
                if v_perms.include?("x")
                    v_folderpermission.permission_execute ="x"
                end
                v_folderpermission.save
           end
        end
        v_group_array.each do |group|
            v_perms=v_group_permission_hash[group]
            puts "gggg group="+group+" "+v_perms
           v_folderpermissions = Folderpermission.where("folder_id in (?) and network_group in (?) and actual_vs_planned in (?)",folder.id,group,"actual")
           if !v_folderpermissions.nil? and v_folderpermissions.count > 0
                v_folderpermissions.each do |v_folderpermission|
                  if v_perms.include?("r")
                    v_folderpermission.permission_read ="r"
                  end
                  if v_perms.include?("w")
                    v_folderpermission.permission_write ="w"
                  end
                  if v_perms.include?("x")
                    v_folderpermission.permission_execute ="x"
                  end
                  v_folderpermission.save
                end
           else
                v_folderpermission = Folderpermission.new
                v_folderpermission.folder_id = folder.id
                v_folderpermission.actual_vs_planned = "actual"
                v_folderpermission.network_group = group
                if v_perms.include?("r")
                    v_folderpermission.permission_read ="r"
                end
                if v_perms.include?("w")
                    v_folderpermission.permission_write ="w"
                end
                if v_perms.include?("x")
                    v_folderpermission.permission_execute ="x"
                end
                v_folderpermission.save
           end
        end


     end
  end

  def folder_home
    self.collect_folder_actual_permissions
     @v_next_one_hash = Hash.new
     @v_next_two_hash = Hash.new
     @v_next_three_hash = Hash.new
     @v_next_four_hash = Hash.new
     @v_next_five_hash = Hash.new
     
     @v_top_count_hash = Hash.new # used to define colspan in parent cells/table 

     @top_folder = Folder.where("folders.parent_id not in ( select id from folders)")
     @top_folder.each do |top|
       @v_top_count_hash[top.id] = 1
       @next_one_folder = Folder.where("parent_id in (?)",top.id)
       if !@next_one_folder.nil?
          @v_next_one_hash[top.id] = @next_one_folder
          @v_top_count_hash[top.id] = @next_one_folder.count
          @next_one_folder.each do |nextfol_one|   
             @next_two_folder = Folder.where("parent_id in (?)",nextfol_one.id)
             if !@next_two_folder.nil? and @next_two_folder.count > 0
                 @v_next_two_hash[nextfol_one.id] = @next_two_folder
                 @v_top_count_hash[top.id] = @next_two_folder.count
                 @next_two_folder.each do |nextfol_two|   
                   @next_three_folder = Folder.where("parent_id in (?)",nextfol_two.id)
                   if !@next_three_folder.nil? and @next_three_folder.count > 0
                     @v_next_three_hash[nextfol_two.id] = @next_three_folder
                     @v_top_count_hash[top.id] = @next_three_folder.count
                     @next_three_folder.each do |nextfol_three|   
                       @next_four_folder = Folder.where("parent_id in (?)",nextfol_three.id)
                       if !@next_four_folder.nil? and @next_four_folder.count > 0
                         @v_next_four_hash[nextfol_three.id] = @next_four_folder
                         @v_top_count_hash[top.id] = @next_four_folder.count
                         @next_four_folder.each do |nextfol_four|   
                           @next_five_folder = Folder.where("parent_id in (?)",nextfol_four.id)
                           if !@next_five_folder.nil? and @next_five_folder.count > 0
                             @v_next_five_hash[nextfol_four.id] = @next_five_folder
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
