class Api::V1::ImageDatasetMetadataLabelsController < API::APIController
	respond_to :json, :csv

	rescue_from UnpermittedParameterValue, with: :invalid_parameters
	before_action :authorize_my_request

	def index
		# This controller is for populating UI elements that need autofill for searching on DICOM metadata. 
		# Since there's nothing like PHI coming out of this controller, we don't need to filter for things 
		# like the scan procedures that the current user is on. 

		labels = ImageDatasetMetadataLabel.where("label like '%#{label_params[:label_filter]}%' or address like '%#{label_params[:label_filter]}%'")

		response_json = []

		labels.each do |label|
			response_json << {'id' => label.id,
							'address' => label.address,
							'label' => label.label, 
							'display_label' => "(#{label.address}) #{label.label}"
							}
		end

		response =  {'data' => response_json}

		render :json => response

	end

	private

	def label_params

		params.permit(:label_filter)
	end

end
