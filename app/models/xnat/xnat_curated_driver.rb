class Xnat::XnatCuratedDriver < Xnat::XnatCurated

  	belongs_to :project, :class_name => "XnatCuratedProject", foreign_key: :project_id

  	#this one doesn't inherit from XnatCurated, because it doesn't do all of the syncing with the 
 	# mothership stuff that the others do.

end 