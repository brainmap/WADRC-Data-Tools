class RadiologyOverreadForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :id, :scan_entry_date, :rmr, :gender, :dob, :white_matter_change, :adrc_large_vessel_infarcts
	attr_accessor :adrc_lacunar_infarcts, :adrc_macrohemorrhages, :adrc_microhemorrhages
	attr_accessor :adrc_moderate_white_matter_hyperintensity, :adrc_extensive_white_matter_hyperintensity
	attr_accessor :summary, :comments
	attr_accessor :clerical_notes, :reader_last_name, :reader_first_name, :read_date
	attr_accessor :mpnrage_uncorrected, :mpnrage_classic_moco, :mpnrage_new_recon, :white_matter_score



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
			'id' => nil,
			"clerical_notes" => nil,
			"reader_last_name" => nil,
			"reader_first_name" => nil,
			"read_date" => nil,
			"mpnrage_uncorrected" => nil,
			"mpnrage_classic_moco" => nil,
			"mpnrage_new_recon" => nil,
			"white_matter_score" => nil
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

		choices['white_matter_score'] = json['whiteMatterScore']
		choices['white_matter_change'] = json['White Matter Change?']
		choices['adrc_large_vessel_infarcts'] = json['ADRC_large_vessel_infarcts']
		choices['adrc_lacunar_infarcts'] = json['ADRC_lacunar_infarcts']
		choices['adrc_macrohemorrhages'] = json['ADRC_macrohemorrhages']
		choices['adrc_microhemorrhages'] = json['ADRC_microHemorrhages']
		choices['adrc_moderate_white_matter_hyperintensity'] = json['ADRC_moderate_white_matter_hyperintensity']
		choices['adrc_extensive_white_matter_hyperintensity'] = json['ADRC_extensive_white_matter_hyperintensity']
		choices['summary'] = json['summary']
		choices['comments'] = json['comments']


		choices['clerical_notes'] = json["clericalNotes"]
		choices['reader_last_name'] = json["readerLastName"]
		choices['reader_first_name'] = json["readerFirstName"]
		choices['read_date'] = json["readDate"]
		choices['mpnrage_uncorrected'] = json["MPnRAGE_uncorrected"]
		choices['mpnrage_classic_moco'] = json["MPnRAGE_classicMoco"]
		choices['mpnrage_new_recon'] = json["MPnRAGE_newRecon"]

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
			'id' => @id,
			"clerical_notes" => @clerical_notes,
			"reader_last_name" => @reader_last_name,
			"reader_first_name" => @reader_first_name,
			"read_date" => @read_date,
			"mpnrage_uncorrected" => @mpnrage_uncorrected,
			"mpnrage_classic_moco" => @mpnrage_classic_moco,
			"mpnrage_new_recon" => @mpnrage_new_recon,
			"white_matter_score" => @white_matter_score
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
			:clerical_notes => { as: :text },
			:reader_last_name => { as: :string },
			:reader_first_name => { as: :string },
			:read_date => { as: :string, input_html: { class: 'datepicker-input'}, label: "Read date"},
			:mpnrage_uncorrected => { as: :string },
			:mpnrage_classic_moco => { as: :string },
			:mpnrage_new_recon => { as: :string },
			:white_matter_score => { as: :string }
		}
	end
end
