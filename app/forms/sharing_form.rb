class SharingForm

	# 2021-06-01 wbbevis - This is for making new / updating sharing settings. Hopefully will be pretty universal.

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :shareable_id, :shareable_type, :can_share, :can_share_wrap, :can_share_up
	attr_accessor :can_share_internal, :can_share_adrc

	# ["WRAPNo", "DBID", "Reggieid", "VisNo", "dtBlood", "AgeAtBlood"]

	def self.attributes
		{
			'shareable_id' => '',
			'shareable_type' => '',
			'can_share' => '',
			'can_share_wrap' => '',
			'can_share_up' => '',
			'can_share_internal' => '',
			'can_share_adrc' => ''
		}
	end

	def self.from_form (row)
		choices = {}

		choices['shareable_id'] = row["shareable_id"]
		choices["shareable_type"] = row["shareable_type"]
		
		choices['can_share'] = row["can_share"]
		choices['can_share_wrap'] = row["can_share_wrap"]
		choices['can_share_up'] = row["can_share_up"]
		choices['can_share_internal'] = row["can_share_internal"]
		choices['can_share_adrc'] = row["can_share_adrc"]

		return self.new(choices)
	end

	def attributes
		{
			'shareable_id' => @shareable_id,
			'shareable_type' => @shareable_type,
			'can_share' => @can_share,
			'can_share_wrap' => @can_share_wrap,
			'can_share_up' => @can_share_up,
			'can_share_internal' => @can_share_internal,
			'can_share_adrc' => @can_share_adrc

		}
	end

	def form_options
		{
			:id => { as: :hidden },
			:shareable_id => { as: :hidden},
			:shareable_type => { as: :hidden },
			:can_share => { as: :string },
			:can_share_wrap => { as: :string, input_html: { class: 'datepicker-input'}, label: "DOB"},
			:can_share_up => { as: :string },
			:can_share_internal => { as: :string },
			:can_share_adrc => { as: :string }
		}
	end

end

