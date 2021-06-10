class Api::V1::SharingController < API::APIController
	respond_to :json, :csv

	rescue_from UnpermittedParameterValue, with: :invalid_parameters
	before_action :authorize_my_request
	before_action :validate_sharing_params

	def update

		sharing_form = SharingForm.from_params(sharing_update_params[:sharing_form])

		if sharing_form.valid?
			# puts "its' valid!"

			sharing = Sharing.find(sharing_update_params[:sharing_form][:id])
			sharing.from_form(sharing_form)

			
			if !sharing.save()
				render :json => {'success' => false, 'errors' => sharing.errors.messages }, :status => 403
			else
				render :json => {'success' => true, 'id' => sharing.id}
			end
		else
			# puts "not valid: " + visit_form.errors.messages.to_s
			render :json => {'success' => false, 'errors' => sharing_form.errors.messages }, :status => 403
		end 


	end


	def create

		sharing_form = SharingForm.from_params(sharing_update_params[:sharing_form])

		if sharing_form.valid?

			sharing = Sharing.new()
			sharing.from_form(sharing_form)
			sharing.save()

			render :json => {'success' => true, 'id' => sharing.id}

		else
			# puts "not valid: " + lp_form.errors.messages.to_s
			render :json => {'success' => false, 'errors' => sharing_form.errors.messages}, :status => 403
		end 

	end

	private

	def sharing_update_params
		params.permit(:id, sharing_form: [:id, :sharing_id, :sharing_type, :can_share, :can_share_wrap, :can_share_adrc, :can_share_internal, :can_share_up])
	end
	def sharing_create_params
		params.permit(:id, sharing_form: [:id, :sharing_id, :sharing_type, :can_share, :can_share_wrap, :can_share_adrc, :can_share_internal, :can_share_up])
	end

	def validate_sharing_params

		# ??
	end

end
