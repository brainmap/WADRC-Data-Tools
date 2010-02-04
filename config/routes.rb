ActionController::Routing::Routes.draw do |map|
  map.resources :physiology_text_files
  map.resources :neuropsych_assessments
  map.resources :neuropsych_sessions

  map.found_visits '/visits/found(.:format)', :controller => 'visits', :action => 'found'
  map.find_visits 'visits/find', :controller => 'visits', :action => 'find'
  map.complete '/visits/complete', :controller => 'visits', :action => 'index_by_scope', :scope => 'complete'
  map.incomplete '/visits/incomplete', :controller => 'visits', :action => 'index_by_scope', :scope => 'incomplete'
  map.recently_imported '/visits/recently_imported', :controller => 'visits', :action => 'index_by_scope', :scope => 'recently_imported'
  map.assigned_to '/visits/assigned_to/:user_login', :controller => 'visits', :action => 'index_by_user_id'
  map.in_scan_procedure '/visits/in_scan_procedure/:scan_procedure_id', :controller => 'visits', :action => 'index_by_scan_procedure'
  
  map.resources :studies
  map.resources :recruitment_groups
  map.resources :withdrawls
  map.resources :enrollments
  map.resources :series_descriptions
  map.resources :participants
  map.resources :analysis_memberships
  map.resources :users
  map.resource :session
  map.resources :visits, :collection => { :complete => :get, :incomplete => :get, :recently_imported => :get, :by_month => :get, :by_week => :get, :find => :get, :found => :get }, :shallow => true do |visit|
    visit.resources :image_datasets, :shallow => true do |image_dataset|
      image_dataset.resources :image_comments
      image_dataset.resources :image_dataset_quality_checks
    end
  end
    
  map.resources :raw_image_files
  map.resources :analyses
  map.resources :image_searches
  # map.resources :image_datasets, :shallow => true do |image_dataset|
  #   image_dataset.resources :image_comments
  #   image_dataset.resources :image_dataset_quality_checks
  # end
  map.resources :image_dataset_quality_checks, :only => [:index]
  map.resources :image_comments, :only => [:index]
  map.resources :scan_procedures
  map.resources :log_files
  map.resources :raw_data_imports

  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login  '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  map.root :controller => "visits", :action=>"index"

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
