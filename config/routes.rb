WADRCDataTools::Application.routes.draw do


  resources :usernetworkgroups
  resources :networkgroups
  resources :trfileimages
  resources :processedimagesfiletypes
  resources :processedimagessources
  resources :processedimages
  resources :consent_form_vgroups
  resources :consent_form_scan_procedures


  resources :consent_forms


  resources :tnfiles


  resources :series_description_scan_procedures


  resources :cg_table_types


  resources :questionformnamesps


  resources :petfiles


  resources :tredit_actions


  resources :tredits


  resources :tractiontypes


  resources :trfiles


  resources :trtypes


  resources :series_description_maps

  resources :series_description_types

  resources :scheduleruns

  resources :schedules

  resources :cg_query_tn_cns

  resources :cg_query_tns

  resources :cg_queries

  resources :cg_tn_cns

  resources :cg_tns

  resources :questionnaires

  resources :blooddraws

  resources :scan_procedures_vgroups

  resources :neuropsyches

  resources :vitals

  resources :petscans

  resources :lumbarpuncture_results

  resources :lookup_lumbarpunctures

  resources :lumbarpunctures

  resources :appointments

  resources :q_data

  resources :q_data_forms

  resources :question_scan_procedures

  resources :questionform_scan_procedures

  resources :question_scan_protocols

  resources :questionform_questions

  resources :questions

  resources :questionform_scan_protocols

  resources :questionforms

  resources :medicationdetails

  resources :employees

  resources :lookup_refs

  resources :lookup_switchboards

  resources :lookup_visitfrequencies

  resources :lookup_truthtables

  resources :lookup_statuses

  resources :lookup_sources

  resources :lookup_sets

  resources :lookup_scantasks

  resources :lookup_imagingplanes

  resources :lookup_relationships

  resources :lookup_recruitsources

  resources :lookup_pettracers

  resources :lookup_rads

  resources :lookup_pettraces

  resources :lookup_letterlabels

  resources :lookup_hardwares

  resources :lookup_genders

  resources :lookup_famhxes

  resources :lookup_ethnicities

  resources :lookup_eligibilityoutcomes

  resources :lookup_eligibility_ineligibilities

  resources :lookup_drugunits

  resources :lookup_drugfreqs

  resources :lookup_drugcodes

  resources :lookup_drugclasses

  resources :lookup_demographicmaritalstatuses

  resources :lookup_diagnoses

  resources :lookup_demographicrelativerelationships

  resources :lookup_demographicmaritialstatuses

  resources :lookup_demographicincomes

  resources :lookup_demographichandednesses

  resources :lookup_consentforms

  resources :lookup_consentcohorts

  resources :lookup_cohorts

  resources :lookup_cogstatuses

  resources :lookup_bvmtpercentiles

  resources :protocol_roles
  resources :protocols
  ###?? match '/users/sign_up', :controller => 'users', :action => 'add_user', :as => :add_user ,via: [:get, :post]
   # want to use adminrole limited add user form instead of devise
  devise_for :users

  resources :physiology_text_files
  resources :neuropsych_assessments
  resources :neuropsych_sessions
  
  resources :directories do
  	collection do
  		post :sort
  	end
	end 
     
  match '/visits/found(.:format)', :to => 'visits#found', :as => :found_visits, via: [:get, :post]
  match '/visits/find', :to => 'visits#find', :as => :find_visits ,via: [:get, :post]
  match '/visits/complete', :to => 'visits#index_by_scope', :scope => 'complete', :as => :complete_visits ,via: [:get, :post]
  match '/visits/incomplete', :to => 'visits#index_by_scope', :scope => 'incomplete', :as => :incomplete_visits ,via: [:get, :post]
  match '/visits/recently_imported', :to => 'visits#index_by_scope', :scope => 'recently_imported', :as => :recently_imported_visits  ,via: [:get, :post]
  match '/visits/assigned_to/:user_login', :controller => 'visits', :action => 'index_by_user_id', :as => :assigned_to ,via: [:get, :post]
  match '/visits/in_scan_procedure/:scan_procedure_id', :controller => 'visits', :action => 'index_by_scan_procedure', :as => :in_scan_procedure  ,via: [:get, :post]
  match '/visits/visit_search' , :controller => 'visits', :action => 'visit_search', :as =>:visit_search ,via: [:get, :post]
##???  match '/visit_search' , :controller => 'visits', :action => 'visit_search', :as =>:visit_search ,via: [:get, :post]
  match '/mri_search' , :controller => 'visits', :action => 'mri_search', :as =>:mri_search   ,via: [:get, :post] 
 ##??? match '/visits/mri_search' , :controller => 'visits', :action => 'mri_search', :as =>:mri_search  ,via: [:get, :post] 
  match '/visits/change_directory_path', :controller => 'visits', :action => 'change_directory_path', :as =>:change_directory_path ,via: [:get, :post] 
  match '/visits/series_desc_cnt', :controller => 'visits', :action => 'series_desc_cnt', :as =>:series_desc_cnt   ,via: [:get, :post] 
  
    match '/petscan_search' , :controller => 'petscans', :action => 'petscan_search', :as =>:petscan_search  ,via: [:get, :post] 
    match '/pet_search' , :controller => 'petscans', :action => 'pet_search', :as =>:pet_search   ,via: [:get, :post]  
    match '/lumbarpuncture_search' , :controller => 'lumbarpunctures', :action => 'lumbarpuncture_search', :as =>:lumbarpuncture_search ,via: [:get, :post] 
    match '/lp_search' , :controller => 'lumbarpunctures', :action => 'lp_search', :as =>:lp_search  ,via: [:get, :post] 
    # match '/lumbarpunctures/lp_search' , :controller => 'lumbarpunctures', :action => 'lp_search', :as =>:lp_search
    match '/blooddraw_search' , :controller => 'blooddraws', :action => 'blooddraw_search', :as =>:blooddraw_search    ,via: [:get, :post] 
    match '/lh_search' , :controller => 'blooddraws', :action => 'lh_search', :as =>:lh_search      ,via: [:get, :post] 
    match '/neuropsych_search' , :controller => 'neuropsyches', :action => 'neuropsych_search', :as =>:neuropsych_search     ,via: [:get, :post] 
    match '/np_search' , :controller => 'neuropsyches', :action => 'np_search', :as =>:np_search   ,via: [:get, :post] 
    match '/questionnaire_search' , :controller => 'questionnaires', :action => 'questionnaire_search', :as =>:questionnaire_search ,via: [:get, :post] 
    match '/q_search' , :controller => 'questionnaires', :action => 'q_search', :as =>:q_search  ,via: [:get, :post] 
    match '/ids_search' , :controller => 'image_datasets', :action => 'ids_search', :as =>:ids_search ,via: [:get, :post] 
    match '/processedimage_search' , :controller => 'processedimages', :action => 'processedimage_search', :as =>:processedimage_search  ,via: [:get, :post] 
     
   
  match '/series_description_map_search' , :controller => 'series_description_maps', :action => 'series_description_map_search', :as =>:series_description_map_search  ,via: [:get, :post]
    match '/enrollment_search' , :controller => 'enrollments', :action => 'enrollment_search', :as =>:enrollment_search    ,via: [:get, :post] 
    match '/participant_search' , :controller => 'participants', :action => 'participant_search', :as =>:participant_search  ,via: [:get, :post] 
    match '/participant_show_pdf' , :controller => 'participants', :action => 'participant_show_pdf', :as =>:participant_show_pdf  ,via: [:get, :post] 
    
  match '/cg_search' , :controller => 'data_searches', :action => 'cg_search', :as =>:cg_search  ,via: [:get, :post] 
  match '/cg_tables' , :controller => 'data_searches', :action => 'cg_tables', :as =>:cg_tables ,via: [:get, :post] 
  match '/cg_edit_table/:id' , :controller => 'data_searches', :action => 'cg_edit_table', :as =>:cg_edit_table   ,via: [:get, :post] 
  match '/cg_edit_dashboard_table/:id' , :controller => 'data_searches', :action => 'cg_edit_dashboard_table', :as =>:cg_edit_dashboard_table   ,via: [:get, :post] 

    match '/cg_table_create_db' , :controller => 'data_searches', :action => 'cg_create_table_db', :as =>:cg_create_table_db ,via: [:get, :post] 
     match '/cg_up_load' , :controller => 'data_searches', :action => 'cg_up_load', :as =>:cg_up_load   ,via: [:get, :post] 
     match '/cg_snapshot' , :controller => 'data_searches', :action => 'cg_snapshot', :as =>:cg_snapshot   ,via: [:get, :post] 
      match '/cg_table_edit_db' , :controller => 'data_searches', :action => 'cg_edit_table_db', :as =>:cg_edit_table_db   ,via: [:get, :post] 
  match '/schedulerun_search' , :controller => 'scheduleruns', :action => 'schedulerun_search', :as =>:schedulerun_search   ,via: [:get, :post] 
  match '/shared_file_upload' , :controller => 'shared', :action => 'file_upload', :as =>:file_upload   ,via: [:get, :post] 

  match '/cg_tns_index' , :controller => 'cg_tns', :action => 'index', :as =>:index   ,via: [:get, :post] 
    match '/cg_tn_cns_index' , :controller => 'cg_tn_cns', :action => 'index', :as =>:cg_tn_cns_index   ,via: [:get, :post] 
    match '/cg_tn_cns/tn_cols/:id' , :controller => 'cg_tn_cns', :action => 'tn_cols', :as =>:tn_cols   ,via: [:get, :post] 
    match '/cg_tns/create_from_cg_tn_db' , :controller => 'cg_tns', :action => 'create_from_cg_tn_db', :as =>:create_from_cg_tn_db  ,via: [:get, :post] 
  
  match '/run_schedule/:id' ,:controller =>'schedules', :action => 'run_schedule', :as => :run_schedule  ,via: [:get, :post] 
  match '/stop_schedule/:id' ,:controller =>'schedules', :action => 'stop_schedule', :as => :stop_schedule  ,via: [:get, :post] 

  match '/participant_merge', :controller => 'participants', :action => 'merge_participants', :as => :merge_participants  ,via: [:get, :post] 
  
  match '/users/update_role', :controller => 'users', :action => 'update_role', :as => :update_role  ,via: [:get, :post] 
  match '/users/user_protocol_role_summary', :controller => 'users', :action => 'user_protocol_role_summary', :as => :user_protocol_role_summary ,via: [:get, :post] 
  match '/users/control', :controller => 'users', :action => 'control', :as => :control  ,via: [:get, :post] 
  match '/users/participant_missing', :controller => 'users', :action => 'participant_missing', :as => :participant_missing  ,via: [:get, :post] 
  match '/users/questionformbase', :controller => 'users', :action => 'questionformbase', :as => :questionformbase,via: [:get, :post] 
  match '/users/cgbase', :controller => 'users', :action => 'cgbase', :as => :cgbase  ,via: [:get, :post] 
  match '/users/add_user', :controller => 'users', :action => 'add_user', :as => :add_user  ,via: [:get, :post] 
  match '/users/edit_user', :controller => 'users', :action => 'edit_user', :as => :edit_user   ,via: [:get, :post] 
  match '/questionform/displayform/:id', :controller=>'questionforms',:action=>'displayform', :as => :displayform  ,via: [:get, :post] 
  match '/questionform/editform/:id', :controller=>'questionforms',:action=>'editform', :as => :editform ,via: [:get, :post] 
    match '/questionform/question_enter', :controller=>'questionforms',:action=>'question_enter', :as => :question_enter   ,via: [:get, :post] 
  # moved up to get precidance over devise sign_upmatch '/users/sign_up', :controller => 'users', :action => 'add_user', :as => :add_user
  
   match '/question/clone/:id', :controller=>'questions',:action=>'clone', :as => :clone   ,via: [:get, :post] 
   match '/questionform_questions/index_sp_questions', :controller=>'questionform_questions',:action=>'index_sp_questions', :as => :index_sp_questions  ,via: [:get, :post] 

    ##??? match '/tredits/tredit_home/:trtype_id', :controller => 'tredits', :action => 'tredit_home', :as => :tredit_home  ,via: [:get, :post] 
    match '/tredit_home/:trtype_id', :controller => 'tredits', :action => 'tredit_home', :as => :tredit_home  ,via: [:get, :post] 
    match 'trfiles/trfile_edit_action', :controller => 'trfiles', :action => 'trfile_edit_action', :as => :trfile_edit_action  ,via: [:get, :post] 
    match '/trfile_home/:id', :controller => 'trfiles', :action => 'trfile_home', :as => :trfile_home,via: [:get, :post] 
    match '/trtype_home/:id', :controller => 'trtypes', :action => 'trtype_home', :as => :trtype_home_id  ,via: [:get, :post]
    match '/trtypes/trtype_home/:id', :controller => 'trtypes', :action => 'trtype_home', :as => :trtypes_trtype_home_id  ,via: [:get, :post] 
    match '/trtype_home/', :controller => 'trtypes', :action => 'trtype_home', :as => :trtype_home  ,via: [:get, :post] 
   
   #match '/vgroups/home', :controller => 'vgroups', :action => 'home', :as => :home
    match '/vgroups/home', :controller => 'vgroups', :action => 'vgroups_search', :as => :home  ,via: [:get, :post] 
   match '/vgroups/vgroups_search', :controller => 'vgroups', :action => 'vgroups_search', :as => :vgroups_search ,via: [:get, :post] 
   match '/vgroups/complete', :to => 'vgroups#index_by_scope', :scope => 'complete', :as => :complete_vgroups  ,via: [:get, :post] 
   match '/vgroups/incomplete', :to => 'vgroups#index_by_scope', :scope => 'incomplete', :as => :incomplete_vgroups    ,via: [:get, :post] 
   match '/vgroups/recently_imported', :to => 'vgroups#index_by_scope', :scope => 'recently_imported', :as => :recently_imported_vgroups  ,via: [:get, :post] 
   match '/vgroups/assigned_to/:user_login', :controller => 'vgroups', :action => 'index_by_user_id', :as => :assigned_to_vgroup ,via: [:get, :post] 
   match '/vgroups/in_scan_procedure/:scan_procedure_id', :controller => 'vgroups', :action => 'index_by_scan_procedure', :as => :in_scan_procedure_vgroup   ,via: [:get, :post] 
   match '/vgroups/in_enumber/:enumber', :controller => 'vgroups', :action => 'index_by_enumber', :as => :in_enumber_vgroup  ,via: [:get, :post] 
   #match '/vgroups/in_scan_procedure', :controller => 'vgroups', :action => 'home', :as => :home
   #match '/vgroups/in_enumber', :controller => 'vgroups', :action => 'home', :as => :home
   match '/vgroups/nii_file_cnt', :controller => 'vgroups', :action => 'nii_file_cnt', :as =>:nii_file_cnt   ,via: [:get, :post] 
      
    match '/vgroups/vgroup_search' , :controller => 'vgroups', :action => 'vgroup_search', :as =>:vgroup_search ,via: [:get, :post] 
    match '/vgroups/change_qc_vgroup', :controller => 'vgroups', :action => 'change_qc_vgroup', :as =>:change_qc_vgroup ,via: [:get, :post] 
   match '/vgroups/change_appointment_vgroup', :controller => 'vgroups', :action => 'change_appointment_vgroup', :as =>:change_appointment_vgroup   ,via: [:get, :post] 
   match '/vgroups/change_transfer_mri_vgroup', :controller => 'vgroups', :action => 'change_transfer_mri_vgroup', :as =>:change_transfer_mri_vgroup  ,via: [:get, :post] 
   match '/vgroups/change_transfer_pet_vgroup', :controller => 'vgroups', :action => 'change_transfer_pet_vgroup', :as =>:change_transfer_pet_vgroup   ,via: [:get, :post] 
   match '/vgroups/change_completedlumbarpuncture_vgroup', :controller => 'vgroups', :action => 'change_completedlumbarpuncture_vgroup', :as =>:change_completedlumbarpuncture_vgroup ,via: [:get, :post] 
   match '/vgroups/change_completedblooddraw_vgroup', :controller => 'vgroups', :action => 'change_completedblooddraw_vgroup', :as =>:change_completedblooddraw_vgroup ,via: [:get, :post] 
   match '/vgroups/change_completedneuropsych_vgroup', :controller => 'vgroups', :action => 'change_completedneuropsych_vgroup', :as =>:change_completedneuropsych_vgroup   ,via: [:get, :post] 
   match '/vgroups/change_completedquestionnaire_vgroup', :controller => 'vgroups', :action => 'change_completedquestionnaire_vgroup', :as =>:change_completedquestionnaire_vgroup   ,via: [:get, :post] 
   match 'vgroups/change_consent_form_vgroup',:controller => 'vgroups', :action => 'change_consent_form_vgroup', :as =>:change_consent_form_vgroup   ,via: [:get, :post] 
    match '/placeholder_vgroup', :controller => 'vgroups', :action => 'placeholder_vgroup', :as => :placeholder_vgroup  ,via: [:get, :post] 
  
   resources :vgroups
  resources :studies
  resources :recruitment_groups
  resources :withdrawls
  resources :enrollments
  resources :series_descriptions
  resources :participants
  resources :analysis_memberships
  resources :users
#  resource :session
  resources :image_datasets, :shallow => true do # |image_dataset|
    resources :image_comments,:image_dataset_quality_checks
  end
  resources :radiology_comments
  
  resources :visits, :shallow => true do
    resources :mriscantasks, :shallow => true do
      resources :mriperformances
    end
  end
  resources :roles
  resources :raw_image_files
  resources :analyses
  resources :image_searches
  # resources :image_datasets, :shallow => true do |image_dataset|
  #   image_dataset.resources :image_comments
  #   image_dataset.resources :image_dataset_quality_checks
  # end
  resources :image_dataset_quality_checks, :only => [:index]
  resources :image_comments, :only => [:index]
  resources :scan_procedures
  resources :log_files
  resources :raw_data_imports
  
  #CHANGED HERE!!!!!
#  resources :vgroups, :shallow => true do
#    resources :appointments
#  end
  
  resources :appointments, :shallow => true do
    resources :petscans
    resources :lumbarpunctures
    resources :visits
  end
  
  resources :lumbarpunctures, :shallow => true do
    resources :lumbarpuncture_results
  end

####  match '/signup', :controller => 'users', :action => 'new', :as => :signup
####  match '/login', :controller => 'sessions', :action => 'new', :as => :username
####  match '/logout', :controller => 'sessions', :action => 'destroy', :as => :logout

  root :to => "vgroups#vgroups_search" #"vgroups#home" #"visits#index"
    ## deprecated rails 5.3-- MAY NEED TO ADD route for each controller
match ':controller(/:action(/:id(.:format)))'  ,via: [:get, :post] 

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
