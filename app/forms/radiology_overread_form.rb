class RadiologyOverreadForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :id, :scan_entry_date, :rmr, :gender, :dob, :white_matter_change, :adrc_large_vessel_infarcts
	attr_accessor :adrc_lacunar_infarcts, :adrc_macrohemorrhages, :adrc_microhemorrhages
	attr_accessor :adrc_moderate_white_matter_hyperintensity, :adrc_extensive_white_matter_hyperintensity
	attr_accessor :summary, :comments


	def self.attributes
		{
			'scan_entry_date' => nil,
			'rmr' => nil,
			'gender' => nil, 
			'dob' => nil, 
			'white_matter_change' => nil, 
			'adrc_large_vessel_infarcts' => nil,
			'adrc_lacunar_infarcts' => nil, 
			'adrc_macrohemorrhages' => nil, 
			'adrc_microhemorrhages' => nil,
			'adrc_moderate_white_matter_hyperintensity' => nil, 
			'adrc_extensive_white_matter_hyperintensity' => nil,
			'summary' => nil, 
			'comments' => nil,
			'id' => nil
		}
	end

	def self.from_json (json)
		choices = {}

		choices['scan_entry_date'] = Date.strptime(json['scanEntryDate'], "%Y-%m-%d")
		choices['rmr'] = json['subjID']
		choices['gender'] = json['gender']

		#in some cases, they're sending '0000-00-00' as a dob, which ruby will fail as a bad date.
		if json['DOB'] == '0000-00-00'
			choices['dob'] = nil
		else
			choices['dob'] = !json['DOB'].nil? ? Date.strptime(json['DOB'],"%Y-%m-%d") : nil
		end

		choices['white_matter_change'] = json['whiteMatterChange']
		choices['adrc_large_vessel_infarcts'] = json['ADRC_large_vessel_infarcts']
		choices['adrc_lacunar_infarcts'] = json['ADRC_lacunar_infarcts']
		choices['adrc_macrohemorrhages'] = json['ADRC_macrohemorrhages']
		choices['adrc_microhemorrhages'] = json['ADRC_microHemorrhages']
		choices['adrc_moderate_white_matter_hyperintensity'] = json['ADRC_moderate_white_matter_hyperintensity']
		choices['adrc_extensive_white_matter_hyperintensity'] = json['ADRC_extensive_white_matter_hyperintensity']
		choices['summary'] = json['summary']
		choices['comments'] = json['comments']

		return self.new(choices)
	end


	def attributes
		{
			'scan_entry_date' => @scan_entry_date,
			'rmr' => @rmr,
			'gender' => @gender, 
			'dob' => @dob, 
			'white_matter_change' => @white_matter_change, 
			'adrc_large_vessel_infarcts' => @adrc_large_vessel_infarcts,
			'adrc_lacunar_infarcts' => @adrc_lacunar_infarcts, 
			'adrc_macrohemorrhages' => @adrc_macrohemorrhages, 
			'adrc_microhemorrhages' => @adrc_microhemorrhages,
			'adrc_moderate_white_matter_hyperintensity' => @adrc_moderate_white_matter_hyperintensity, 
			'adrc_extensive_white_matter_hyperintensity' => @adrc_extensive_white_matter_hyperintensity,
			'summary' => @summary, 
			'comments' => @comments,
			'id' => @id
		}
	end

	def form_options
		{
			:id => { as: :hidden },
			:scan_entry_date => { as: :string, input_html: { class: 'datepicker-input'}, label: "Date"},
			:rmr => { as: :string },
			:gender => { as: :string },
			:dob => { as: :string, input_html: { class: 'datepicker-input'}, label: "DOB"},
			:white_matter_change => { as: :string },
			:adrc_large_vessel_infarcts => { as: :string },
			:adrc_lacunar_infarcts => { as: :string },
			:adrc_macrohemorrhages => { as: :string },
			:adrc_microhemorrhages => { as: :string },
			:adrc_moderate_white_matter_hyperintensity => { as: :string },
			:adrc_extensive_white_matter_hyperintensity => { as: :string },
			:summary => { as: :text },
			:comments => { as: :text },
		}
	end
end
