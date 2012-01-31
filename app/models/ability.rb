class Ability
  include CanCan::Ability

  def initialize(user)
   #  user[:var1] ='VVVVV'

    
    alias_action :index, :show, :to => :read
    alias_action :new, :to => :create
    alias_action :edit, :to => :update
    alias_action :update, :destroy, :to => :modify
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
 # can :manage, :all
   
   ## HASHES ALSO SET IN app/models/user.rb  -- transfering from user to set value here
  # make list of roles  -- 
  @roles_in_pr  =  user.protocol_roles.find_by_sql("SELECT DISTINCT role from protocol_roles where user_id = "+(user.id).to_s)
  # loop thru each role

  # error where unioning null arrays 
  user[:view_low_scan_procedure_array] = [0]
  user[:edit_low_scan_procedure_array] = [0]
  user[:admin_low_scan_procedure_array] = [0]
  user[:admin_high_scan_procedure_array] = [0]
  
  user[:view_low_protocol_array] = [0]
  user[:edit_low_protocol_array] = [0]
  user[:edit_high_protocol_array] = [0]
  user[:admin_low_protocol_array] = [0]
  user[:admin_high_protocol_array] = [0]
  

   @roles_in_pr.each do |p| 
      if p.role == "Edit_High"
        # loop thru protocols and grant perms 
         protocol_array = []
      #  @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(user.id).to_s)
      #  @current_user_protocol.each do |p2|
      #    protocol_array << p2.protocol_id
      #    end
        protocol_array =  (user.edit_high_protocol_array).split(' ').map(&:to_i)         
        user[:edit_high_protocol_array] = protocol_array
        
        can [:read, :modify], Protocol do |p3| protocol_array.include?p3.try(:id)
        end
        protocol_list = protocol_array*","
        scan_procedure_array = []
#        @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
#        @current_user_scan_procedure.each do |p2|
#          scan_procedure_array << p2.id
#          end
          scan_procedure_array  = (user.edit_high_scan_procedure_array).split(' ').map(&:to_i) 
        user[:edit_high_scan_procedure_array] = scan_procedure_array
        
       can [:read, :modify] , ScanProcedure do |p3|  scan_procedure_array.include?p3.try(:id)
        end 
        
        visit_array = []
        @current_user_visit = user.protocol_roles.find_by_sql("SELECT distinct visit_id from scan_procedures_visits where scan_procedure_id in (select id from scan_procedures where protocol_id in ("+protocol_list+") ) ")
        @current_user_visit.each do |p2|
          visit_array << p2.visit_id
          end         
        visit_array = []
        can [:read, :modify] , Visit do |p3|  visit_array.include?p3.try(:id)
         end         
        #   participant?
      end

      if p.role == "Edit_Medium"
         # loop thru protocols and grant perms 
          protocol_array = []
#         @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(user.id).to_s)
#         @current_user_protocol.each do |p2|
#           protocol_array << p2.protocol_id
#           end
        protocol_array =  (user.edit_medium_protocol_array).split(' ').map(&:to_i) 
         user[:edit_medium_protocol_array] = protocol_array

         can [:read, :modify], Protocol do |p3| protocol_array.include?p3.try(:id)
         end
         protocol_list = protocol_array*","
         scan_procedure_array = []
#         @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
#         @current_user_scan_procedure.each do |p2|
#           scan_procedure_array << p2.id
#           end
          scan_procedure_array  = (user.edit_medium_scan_procedure_array).split(' ').map(&:to_i) 
         user[:edit_medium_scan_procedure_array] = scan_procedure_array

        can [:read, :modify] , ScanProcedure do |p3|  scan_procedure_array.include?p3.try(:id)
         end 
         
         visit_array = []
         @current_user_visit = user.protocol_roles.find_by_sql("SELECT distinct visit_id from scan_procedures_visits where scan_procedure_id in (select id from scan_procedures where protocol_id in ("+protocol_list+") ) ")
         @current_user_visit.each do |p2|
           visit_array << p2.visit_id
           end         
         visit_array = []
         can [:read, :modify] , Visit do |p3|  visit_array.include?p3.try(:id)
          end         
         #   participant?     
      end
      
      if p.role == "Edit_Low"
         # loop thru protocols and grant perms 
          protocol_array = []
    #     @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(user.id).to_s)
    #     @current_user_protocol.each do |p2|
    #       protocol_array << p2.protocol_id
    #       end
         protocol_array =  (user.edit_low_protocol_array).split(' ').map(&:to_i) 
         user[:edit_low_protocol_array] = protocol_array

         can [:read, :modify], Protocol do |p3| protocol_array.include?p3.try(:id)
         end
         protocol_list = protocol_array*","
         scan_procedure_array = []
    #     @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")

     #    @current_user_scan_procedure.each do |p2|
    #       scan_procedure_array << p2.id
    #       end
        scan_procedure_array = (user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
         user[:edit_low_scan_procedure_array] = scan_procedure_array

        can [:read, :modify] , ScanProcedure do |p3|  scan_procedure_array.include?p3.try(:id)
         end 
         
         visit_array = []
         @current_user_visit = user.protocol_roles.find_by_sql("SELECT distinct visit_id from scan_procedures_visits where scan_procedure_id in (select id from scan_procedures where protocol_id in ("+protocol_list+") ) ")
         @current_user_visit.each do |p2|
           visit_array << p2.visit_id
           end         
         visit_array = []
         can [:read, :modify] , Visit do |p3|  visit_array.include?p3.try(:id)
          end         
         #   participant?      
      end      
      
      if p.role == "View_High"
         # loop thru protocols and grant perms 
          protocol_array = []
   #      @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(user.id).to_s)
  #       @current_user_protocol.each do |p2|
  #         protocol_array << p2.protocol_id
  #         end
        protocol_array =  (user.view_high_protocol_array).split(' ').map(&:to_i) 
         user[:view_high_protocol_array] = protocol_array

         can [:read], Protocol do |p3| protocol_array.include?p3.try(:id)
         end
         protocol_list = protocol_array*","
         scan_procedure_array = []
#         @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
#         @current_user_scan_procedure.each do |p2|
#           scan_procedure_array << p2.id
#           end
          scan_procedure_array  = (user.view_high_scan_procedure_array).split(' ').map(&:to_i) 
         user[:view_high_scan_procedure_array] = scan_procedure_array

        can [:read] , ScanProcedure do |p3|  scan_procedure_array.include?p3.try(:id)
         end 
         
         visit_array = []
         @current_user_visit = user.protocol_roles.find_by_sql("SELECT distinct visit_id from scan_procedures_visits where scan_procedure_id in (select id from scan_procedures where protocol_id in ("+protocol_list+") ) ")
         @current_user_visit.each do |p2|
           visit_array << p2.visit_id
           end         
         visit_array = []
         can [:read, :modify] , Visit do |p3|  visit_array.include?p3.try(:id)
          end         
         #   participant?
      end  

      if p.role == "View_Medium"
         # loop thru protocols and grant perms 
          protocol_array = []
#         @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(user.id).to_s)
#         @current_user_protocol.each do |p2|
#           protocol_array << p2.protocol_id
#           end
         protocol_array =  (user.view_medium_protocol_array).split(' ').map(&:to_i) 
         user[:view_medium_protocol_array] = protocol_array

         can [:read], Protocol do |p3| protocol_array.include?p3.try(:id)
         end
         protocol_list = protocol_array*","
         scan_procedure_array = []
#         @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
#         @current_user_scan_procedure.each do |p2|
#           scan_procedure_array << p2.id
#           end
          scan_procedure_array  = (user.view_medium_scan_procedure_array).split(' ').map(&:to_i) 
         user[:view_medium_scan_procedure_array] = scan_procedure_array

        can [:read] , ScanProcedure do |p3|  scan_procedure_array.include?p3.try(:id)
         end 
         
         visit_array = []
         @current_user_visit = user.protocol_roles.find_by_sql("SELECT distinct visit_id from scan_procedures_visits where scan_procedure_id in (select id from scan_procedures where protocol_id in ("+protocol_list+") ) ")
         @current_user_visit.each do |p2|
           visit_array << p2.visit_id
           end         
         visit_array = []
         can [:read, :modify] , Visit do |p3|  visit_array.include?p3.try(:id)
          end         
         #   participant?       
          
      end
      
      if p.role == "View_Low"
         # loop thru protocols and grant perms 
          protocol_array = []
      #   @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(user.id).to_s)
      #   @current_user_protocol.each do |p2|
      #     protocol_array << p2.protocol_id
      #     end
         protocol_array = (user.view_low_protocol_array).split(' ').map(&:to_i) 
         user[:view_low_protocol_array] = protocol_array
         
         can [:read], Protocol do |p3| protocol_array.include?p3.try(:id)
         end
         protocol_list = protocol_array*","
  #       scan_procedure_array = []
  #       @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
  #       @current_user_scan_procedure.each do |p2|
  #         scan_procedure_array << p2.id
  #         end
          scan_procedure_array = (user.view_low_scan_procedure_array).split(' ').map(&:to_i) 
         user[:view_low_scan_procedure_array] = scan_procedure_array

        can [:read] , ScanProcedure do |p3|  scan_procedure_array.include?p3.try(:id)
         end 

         visit_array = []
         @current_user_visit = user.protocol_roles.find_by_sql("SELECT distinct visit_id from scan_procedures_visits where scan_procedure_id in (select id from scan_procedures where protocol_id in ("+protocol_list+") ) ")
         @current_user_visit.each do |p2|
           visit_array << p2.visit_id
           end         
         visit_array = []
         can [:read] , Visit do |p3|  visit_array.include?p3.try(:id)
          end         
         #   participant?
                 
      end      
      
      if p.role == "Admin_High"
         # loop thru protocols and grant perms 
          protocol_array = []
   #      @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(user.id).to_s)
  #       @current_user_protocol.each do |p2|
  #         protocol_array << p2.protocol_id
  #         end
          protocol_array  = (user.admin_high_protocol_array).split(' ').map(&:to_i)
         user[:admin_high_protocol_array] = protocol_array

         can [:read, :modify], Protocol do |p3| protocol_array.include?p3.try(:id)
         end
         protocol_list = protocol_array*","
         scan_procedure_array = []
  #       @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
  #       @current_user_scan_procedure.each do |p2|
  #         scan_procedure_array << p2.id
  #         end
        scan_procedure_array = (user.admin_high_scan_procedure_array).split(' ').map(&:to_i)   
         user[:admin_high_scan_procedure_array] = scan_procedure_array

        can [:read, :modify] , ScanProcedure do |p3|  scan_procedure_array.include?p3.try(:id)
         end 
         
         visit_array = []
         @current_user_visit = user.protocol_roles.find_by_sql("SELECT distinct visit_id from scan_procedures_visits where scan_procedure_id in (select id from scan_procedures where protocol_id in ("+protocol_list+") ) ")
         @current_user_visit.each do |p2|
           visit_array << p2.visit_id
           end         
         visit_array = []
         can [:read, :modify] , Visit do |p3|  visit_array.include?p3.try(:id)
          end         
         #   participant? 

      end   
      
      if p.role == "Admin_Medium"
         # loop thru protocols and grant perms 
          protocol_array = []
#         @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(user.id).to_s)
#         @current_user_protocol.each do |p2|
#           protocol_array << p2.protocol_id
#           end
          protocol_array  = (user.admin_medium_protocol_array).split(' ').map(&:to_i)
         user[:admin_medium_protocol_array] = protocol_array

         can [:read, :modify], Protocol do |p3| protocol_array.include?p3.try(:id)
         end
         protocol_list = protocol_array*","
         scan_procedure_array = []
#         @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
#         @current_user_scan_procedure.each do |p2|
#           scan_procedure_array << p2.id
#           end
          scan_procedure_array  = (user.admin_medium_scan_procedure_array).split(' ').map(&:to_i) 
         user[:admin_medium_scan_procedure_array] = scan_procedure_array

        can [:read, :modify] , ScanProcedure do |p3|  scan_procedure_array.include?p3.try(:id)
         end 
         
         visit_array = []
         @current_user_visit = user.protocol_roles.find_by_sql("SELECT distinct visit_id from scan_procedures_visits where scan_procedure_id in (select id from scan_procedures where protocol_id in ("+protocol_list+") ) ")
         @current_user_visit.each do |p2|
           visit_array << p2.visit_id
           end         
         visit_array = []
         can [:read, :modify] , Visit do |p3|  visit_array.include?p3.try(:id)
          end         
         #   participant?
         
      end
      
      if p.role == "Admin_Low"
         # loop thru protocols and grant perms 
          protocol_array = []
 #        @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(user.id).to_s)
#         @current_user_protocol.each do |p2|
#           protocol_array << p2.protocol_id
#           end
        protocol_array  = (user.admin_low_protocol_array).split(' ').map(&:to_i)   
         user[:admin_low_protocol_array] = protocol_array

         can [:read, :modify], Protocol do |p3| protocol_array.include?p3.try(:id)
         end
         protocol_list = protocol_array*","
         scan_procedure_array = []
  #       @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
  #       @current_user_scan_procedure.each do |p2|
  #         scan_procedure_array << p2.id
  #         end
          scan_procedure_array  = (user.admin_low_scan_procedure_array).split(' ').map(&:to_i) 
         user[:admin_low_scan_procedure_array] = scan_procedure_array

        can [:read, :modify] , ScanProcedure do |p3|  scan_procedure_array.include?p3.try(:id)
         end 
         
         visit_array = []
         @current_user_visit = user.protocol_roles.find_by_sql("SELECT distinct visit_id from scan_procedures_visits where scan_procedure_id in (select id from scan_procedures where protocol_id in ("+protocol_list+") ) ")
         @current_user_visit.each do |p2|
           visit_array << p2.visit_id
           end         
         visit_array = []
         can [:read, :modify] , Visit do |p3|  visit_array.include?p3.try(:id)
          end         
         #   participant?
         
      end      
  end   
  
  # get list of all protocol and scan_procedure
    protocol_array =[]
  @current_user_protocol = user.protocol_roles.find_by_sql("SELECT distinct id from protocols")
  @current_user_protocol.each do |p2|
    protocol_array << p2.id
    end
    protocol_list = protocol_array*","
    scan_procedure_array = []
    @current_user_scan_procedure = user.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
    @current_user_scan_procedure.each do |p2|
      scan_procedure_array << p2.id
      end    
      
  if user.role == "Admin_High"
      can :manage, :all
   # can :manage, Protocol
  #  can :manage , ScanProcedure
    user[:admin_high_scan_procedure_array] = scan_procedure_array
    user[:admin_high_protocol_array] = protocol_array
  elsif user.role  == "Admin_Medium"
    user[:admin_medium_scan_procedure_array] = scan_procedure_array
    user[:admin_medium_protocol_array] = protocol_array  
  elsif user.role  == "Admin_Low"
    user[:admin_low_scan_procedure_array] = scan_procedure_array
    user[:admin_low_protocol_array] = protocol_array
  elsif user.role  == "Edit_High"
    user[edit_high_scan_procedure_array] = scan_procedure_array
    user[:edit_high_protocol_array] = protocol_array
         
  elsif user.role  == "Edit_Medium"
    user[:edit_medium_scan_procedure_array] = scan_procedure_array
    user[:edit_medium_protocol_array] = protocol_array  
  elsif user.role  == "Edit_Low"
    user[:edit_low_scan_procedure_array] = scan_procedure_array
    user[:edit_low_protocol_array] = protocol_array
    can :read,    :all
    can :modify, :all
    cannot :modify,  User
    cannot  :modify,  Protocol_Role
  elsif user.role  == "View_High"
    user[:view_high_scan_procedure_array] = scan_procedure_array
    user[:view_high_protocol_array] = protocol_array    
  elsif user.role  == "View_Medium"
    user[:view_medium_scan_procedure_array] = scan_procedure_array
    user[:view_medium_protocol_array] = protocol_array
  elsif user.role == "View_Low"
    can :read, :all
    user[:view_low_scan_procedure_array] = scan_procedure_array
    user[:view_low_protocol_array] = protocol_array
    can :read,    :all
  end

  # populate sum of arrays --- admin-> edit
        # admin-> edit -> view 
        # driver is edit_low_,  view_low
      # merging nulls arrays 
      # poplate first user array with -1, pick up new procedures as go along?
      
  user[:edit_low_scan_procedure_array] = user[:edit_low_scan_procedure_array] | user[:admin_low_scan_procedure_array] | user[:admin_high_scan_procedure_array]
  user[:view_low_scan_procedure_array] = user[:edit_low_scan_procedure_array] | user[:view_low_scan_procedure_array]
  
  # also protocol
  user[:edit_low_protocol_array] = user[:edit_low_protocol_array] | user[:admin_low_protocol_array] | user[:admin_high_protocol_array]
  user[:view_low_protocol_array] = user[:edit_low_protocol_array] | user[:view_low_protocol_array] 
  
 #  user[:edit_low_scan_procedure_array] = [-1]
 #  user[:edit_low_protocol_array] = [-1]
        
  
  # default access -- limit in controller
  can [:read,:update,:destroy,:all] , Visit
  ##can [:read], Protocol
  ##can [:read],ScanProcedure
  
  can [:read] , User
  can [:read] , Role
  can [:read, :modify] , RadiologyComment  
  can [:read, :modify] , ProtocolRole
  can [:read, :modify] , Participant
  can [:read, :modify] , ImageSearch
  can [:read, :modify] , ImageDatasetQualityCheck
  can [:read, :modify] , ImageDataset
  can [:read, :modify] , ImageComment
  can [:read, :modify] , EnrollmentVisitMembership 
  can [:read, :modify] , Enrollment
  can [:read, :modify] , AnalysisMembership
  can [:read, :modify] , Analysis


    ### can :update Comment do |comment|
    ###      comment.try(:user) == user
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
