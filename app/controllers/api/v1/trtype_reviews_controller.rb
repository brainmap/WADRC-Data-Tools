class Api::V1::TrtypeReviewsController < API::APIController
	respond_to :json, :csv

	rescue_from UnpermittedParameterValue, with: :invalid_parameters
	# before_action :authorize_my_request
	# before_action :validate_review_params

	def candidates

		scan_procedure_array = @current_user.view_low_scan_procedure_array.split(' ')
		scan_procedure_list = scan_procedure_array.map(&:to_i)

		overall_trfiles = Trfile.where("trtype_id = ?", params[:id]).where("scan_procedure_id" => scan_procedure_list)

		if [:tag_filter].any?{|selector| !review_params[selector].blank? }
			overall_trfiles = overall_trfiles.joins(:tr_tags)
		end

		recordsTotal = Trfile.all.count #overall_trfiles.count

		if !review_params[:subjectid_filter].blank?
			overall_trfiles = overall_trfiles.where("trfiles.subjectid like '%#{review_params[:subjectid_filter]}%'")
		end
		if !review_params[:secondary_key_filter].blank?
			overall_trfiles = overall_trfiles.where("trfiles.secondary_key like '%#{review_params[:secondary_key_filter]}%'")
		end
		if !review_params[:qc_filter].blank?
			overall_trfiles = overall_trfiles.where("trfiles.qc_value = '#{review_params[:qc_filter]}'")
		end
		if !review_params[:completed_filter].blank?
			overall_trfiles = overall_trfiles.where("trfiles.file_completed_flag = '#{review_params[:completed_filter]}'")
		end
		if !review_params[:scan_procedure_filter].blank?
			# puts "filtering for scan procedure (#{review_params[:scan_procedure_filter]})"
			overall_trfiles = overall_trfiles.where("trfiles.scan_procedure_id = #{review_params[:scan_procedure_filter]}")
		end
		if !review_params[:tag_filter].blank?
			# puts "filtering for tag (#{review_params[:tag_filter]})"
			overall_trfiles = overall_trfiles.where("tr_tags_trfiles.tr_tag_id = #{review_params[:tag_filter]}")
		end

		overall_trfiles = overall_trfiles.distinct
		recordsFiltered = overall_trfiles.count

		#we also need to order by, and we'll take the param datatables style
		client_side_columns = ['trfiles.file_completed_flag',
			'trfiles.updated_at',
			'trfiles.subjectid',
			'',
			'trfiles.scan_procedure_id',
			'',
			'',
		]
		if !review_params[:order].blank?
			overall_trfiles = overall_trfiles.reorder("")
			review_params[:order].each do |idx, order|
				#Some sorting we can't really implement, so this is a quick way to set up non-sortable. 
				if !client_side_columns[order['column'].to_i].blank?
					puts "#{client_side_columns[order['column'].to_i]} #{order['dir']}"
					overall_trfiles = overall_trfiles.order("#{client_side_columns[order['column'].to_i]} #{order['dir']}")
				end
			end
		end

		displayable_tractiontypes = Tractiontype.where("trtype_id = ?",params[:id]).where("display_in_summary = 'Y'")

		case request.format
		when "application/json"

			trfiles_page = overall_trfiles.limit(review_params[:length]).offset(review_params[:start])

			response_json = []

			#I don't want to hammer LookupRefs with queries for each member of my checks column, so I'm 
			# going to build a little hash I can use for labels. This is much faster.
			label_map = {}
			displayable_tractiontypes.map(&:ref_table_b_1).uniq.each do |label|
				label_map[label] = LookupRef.where("label = ?",label).order(:display_order).map{|lookup_ref| [lookup_ref.ref_value,lookup_ref.description]}.to_h
			end

			trfiles_page.each do |file|
				tredits = Tredit.where("trfile_id = ?", file.id)
				tredit_actions = TreditAction.where("tredit_id in (?)",tredits.map(&:id)) #.where("tractiontype_id in (?)",displayable_tractiontypes.map(&:id))

				checks = []

				tredit_actions.each do |tredit_action|

					tractiontype = Tractiontype.find(tredit_action.tractiontype_id)
					if displayable_tractiontypes.map(&:id).include? tredit_action.tractiontype_id
						# puts "label options are #{label_map[tractiontype.ref_table_b_1].to_s}"
						value = (label_map[tractiontype.ref_table_b_1][tredit_action.value.to_i])
						# puts "treditaction.value is #{tredit_action.value.to_s}, value is #{value}"
						checks << {'title' => tractiontype.display_column_header_1,
								'value'=> value }
					else
						checks << {'title' => tractiontype.display_column_header_1,
								'value'=> tredit_action.value}

					end

				end

				puts "json: " + JSON.generate(checks)

				scan_procedure = ScanProcedure.where("id = ?",file.scan_procedure_id).first
				scan_proc_name = ''
				if !scan_procedure.nil?
					scan_proc_name = scan_procedure.display_alias
				end

				response_json << {'id' => file.id,
									'completed' => file.file_completed_flag,
									'updated_at' => file.updated_at.strftime("%Y-%m-%d %H:%M"), 
									'subjectid' => file.subjectid,
									'scan_procedure' => scan_proc_name,
									'qc_value' => file.qc_value,
									'checks' => checks,
									'file_completed_flag' => file.file_completed_flag
								}
			end

			response =  {'recordsTotal' => recordsTotal,'recordsFiltered' => recordsFiltered, 'data' => response_json, 'draw' => review_params[:draw].to_i}

			render :json => response

		when "text/csv"

			trfiles_page = overall_trfiles #.limit(review_params[:length]).offset(review_params[:start])

			response_csv = CSV.generate do |csv|
				csv << ['trfile_id','completed','updated_at','subjectid','qc_value','scan_procedure']


				trfiles_page.each do |file|
					scan_procedure = ScanProcedure.where("id = ?",file.scan_procedure_id).first
					scan_proc_name = ''
					if !scan_procedure.nil?
						scan_proc_name = scan_procedure.display_alias
					end

					csv << [file.id,
							file.file_completed_flag,
							file.updated_at.strftime("%Y-%m-%d %H:%M"), 
							file.subjectid,
							file.qc_value,
							scan_proc_name
						]
				end
			end

            send_data response_csv, :type => 'text/csv; charset=utf-8; header=present', :disposition => "attachment; filename=trtype.csv", :filename => "trtype.csv"
        
		end
	end

	def fields

		scan_procedure_array = @current_user.view_low_scan_procedure_array.split(' ')
		scan_procedure_list = scan_procedure_array.map(&:to_i)

		trtype = Trtype.find(params[:id])

		file = Trfile.where("trtype_id = ?", params[:id]).where("id" => params[:trfile_id]).first

		displayable_tractiontypes = Tractiontype.where("trtype_id = ?",params[:id]).order(:form_display_order)

		case request.format
		when "application/json"

			response_json = []

			#I don't want to hammer LookupRefs with queries for each member of my checks column, so I'm 
			# going to build a little hash I can use for labels. This is much faster.
			label_map = {}
			displayable_tractiontypes.map(&:ref_table_b_1).uniq.each do |label|
				label_map[label] = LookupRef.where("label = ?",label).order(:display_order).map{|lookup_ref| [lookup_ref.ref_value,lookup_ref.description]}.to_h
			end

			# puts "label_map is #{label_map}"

			tredit = Tredit.where("trfile_id = ?", file.id).last

			tredit_actions = TreditAction.where("tredit_id in (?)",tredit.id) #.where("tractiontype_id in (?)",displayable_tractiontypes.map(&:id))

			checks = []

			displayable_tractiontypes.each do |tractiontype|
				if tredit_actions.map(&:tractiontype_id).include? tractiontype.id

					tredit_action = tredit_actions.select{|item| item.tractiontype_id == tractiontype.id}.first

					if tractiontype.id == tredit_action.tractiontype_id

						checks << {'title' => tractiontype.form_display_label,
								'value'=> tredit_action.value,
								'field_type' => tractiontype.form_display_field_type,
								'options' => label_map[tractiontype.ref_table_b_1],
								'form_name' => tractiontype.description,
								'tractiontype_id' => tractiontype.id,
								'popover' => tractiontype.popover
							}
					else
						checks << {'title' => tractiontype.form_display_label,
								'value'=> (tredit_action.value == 'null' or tredit_action.value.blank? ? '' : tredit_action.value),
								'field_type' => tractiontype.form_display_field_type,
								'options' => [],
								'form_name' => tractiontype.description,
								'tractiontype_id' => tractiontype.id,
								'popover' => tractiontype.popover
								}
					end
				end
			end

			images = []

			file.trfileimages.each do |image|
				processedimage = Processedimage.find(image.image_id)
				images << {'id' => processedimage.id,
							'file_path' => processedimage.file_path,
							'file_name' => processedimage.file_name,
							'processed_image_id' => processedimage.id,
							'file_type' => processedimage.file_type
							}
			end

			scan_procedure = ScanProcedure.where("id = ?",file.scan_procedure_id).first
			scan_proc_name = ''
			if !scan_procedure.nil?
				scan_proc_name = scan_procedure.display_alias
			end

			response_json << {'id' => file.id,
								'tredit_id' => tredit.id,
								'completed' => file.file_completed_flag,
								'updated_at' => file.updated_at.strftime("%Y-%m-%d %H:%M"), 
								'subjectid' => file.subjectid,
								'scan_procedure' => scan_proc_name,
								'qc_value' => file.qc_value,
								'qc_value_popover' => trtype.popover,
								'checks' => checks,
								'images' => images
							}

			response =  {'data' => response_json}

			render :json => response

		end
	end

	def update

		puts "posted: #{update_params[:qc_form]}"

		# if trfile_qc_form.valid?

		file = Trfile.find(update_params[:trfile_id].to_i)

		#on the object directly, there's qc_value, and file_completed_flag, which we're going to call 'Y'
		file.qc_value = update_params[:qc_value]
		if update_params[:qc_value] != 'Needs Review'
			file.file_completed_flag = 'Y'
		end

		file.save

		#then, update this tredit
		tredit = Tredit.find(update_params[:tredit_id])
		tredit.user_id = update_params[:user_id].to_i
		tredit.status_flag = 'Y'
		tredit.save

		#then make some new tredit_actions
		ignorable_field_names = ['qc_value', 'tredit_id', 'trfile_id', 'user_id']
		existing_actions = TreditAction.where("tredit_id = ?", tredit.id)
		update_params[:qc_form]['fields'].keys.each do |key|
			# look through tht existing tredit_actions for this tredit, and match with the 'name' field

			if !ignorable_field_names.include? update_params[:qc_form]['fields'][key]['name']
				potential_matches = existing_actions.select{|action| action.tractiontype_id == update_params[:qc_form]['fields'][key]['name'].to_i}
				if potential_matches.count == 1
					#update this match
					field = potential_matches.first
					field.value = update_params[:qc_form]['fields'][key]['value']
					field.save

				end
			end

		end

		render :json => {'success' => true, 'id' => file.id}

		# else
			# puts "not valid: " + lp_form.errors.messages.to_s
			# render :json => {'success' => false, 'errors' => trfile_qc_form.errors.messages}, :status => 403
		# end 

	end

	def new

		puts "posted: #{new_params[:qc_form]}"

		# if trfile_qc_form.valid?

		file = Trfile.find(new_params[:trfile_id].to_i)

		#on the object directly, there's qc_value, and file_completed_flag, which we're going to call 'Y'
		file.qc_value = new_params[:qc_value]
		if new_params[:qc_value] != 'Needs Review'
			file.file_completed_flag = 'Y'
		end

		file.save

		#then, make a new tredit
		tredit = Tredit.new
		tredit.trfile_id = file.id
		tredit.user_id = new_params[:user_id].to_i
		tredit.status_flag = 'Y'
		tredit.save

		#then make some new tredit_actions, and fill them for this new edit
		ignorable_field_names = ['qc_value', 'tredit_id', 'trfile_id', 'user_id']
		fields_to_fill = Tractiontype.where("trtype_id = ?", file.trtype_id)
		new_params[:qc_form]['fields'].keys.each do |key|
			# look through tht existing tredit_actions for this tredit, and match with the 'name' field

			if !ignorable_field_names.include? new_params[:qc_form]['fields'][key]['name']
				potential_matches = fields_to_fill.select{|action| action.id == new_params[:qc_form]['fields'][key]['name'].to_i}
				if potential_matches.count == 1
					#new tredit_action with this tractiontype
					field = TreditAction.new
					field.tredit_id = tredit.id
					field.tractiontype_id = potential_matches.first.id
					field.value = new_params[:qc_form]['fields'][key]['value']
					field.status_flag = 'Y'
					field.save

				end
			end

		end

		render :json => {'success' => true, 'id' => file.id}

		# else
			# puts "not valid: " + lp_form.errors.messages.to_s
			# render :json => {'success' => false, 'errors' => trfile_qc_form.errors.messages}, :status => 403
		# end 

	end

	private

	def review_params
		params.permit(:id, :trtype_id, :trfile_id, :length, :start, :scan_date_before_filter, :scan_procedure_filter, :tag_filter, :subjectid_filter, :secondary_key_filter, :qc_filter, :completed_filter, :scan_date_after_filter, :draw, order: [:column, :dir])
	end


	def update_params
		params.permit(:id, :trfile_id, :tredit_id, :user_id, :qc_value, :qc_form => [:fields => [:name,:value]])
	end

	def new_params
		params.permit(:id, :trfile_id, :tredit_id, :user_id, :qc_value, :qc_form => [:fields => [:name,:value]])
	end

end
