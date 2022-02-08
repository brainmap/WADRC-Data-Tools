
###Create table to house ROI names and ID's. Then insert names and ID's into it

#create_roi_sql = "CREATE TABLE `neuromorph_roi_names` (`id` INT NOT NULL,`roi_name` VARCHAR(255) DEFAULT NULL,PRIMARY KEY (`id`));"
#create_roi_sql = "CREATE TABLE `neuromorph_roi_names` (
#                               `id` INT NOT NULL,
#                               `roi_name` VARCHAR(255) DEFAULT NULL,
#                               PRIMARY KEY (`id`)
#                               );"
#ActiveRecord::Base.connection.execute(create_roi_sql)


#roi_id = [4,11,23,30,31,32,35,36,37,38,39,40,41,44,45,46,47,48,49,50,51,52,55,56,57,58,59,60,61,62,63,64,69,71,72,73,75,76,100,101,102,103,104,105,106,107,108,109,112,113,114,115,116,117,118,119,120,121,122,123,124,125,128,129,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207]


roi_name = ["3rd Ventricle","4th Ventricle","Right Accumbens Area","Left Accumbens Area","Right Amygdala","Left Amygdala","Brain Stem","Right Caudate","Left Caudate","Right Cerebellum Exterior","Left Cerebellum Exterior","Right Cerebellum White Matter","Left Cerebellum White Matter","Right Cerebral White Matter","Left Cerebral White Matter","CSF","Right Hippocampus","Left Hippocampus","Right Inf Lat Vent","Left Inf Lat Vent","Right Lateral Ventricle","Left Lateral Ventricle","Right Pallidum","Left Pallidum","Right Putamen","Left Putamen","Right Thalamus Proper","Left Thalamus Proper","Right Ventral DC","Left Ventral DC","Right vessel","Left vessel","Optic Chiasm","Cerebellar Vermal Lobules I-V","Cerebellar Vermal Lobules VI-VII","Cerebellar Vermal Lobules VIII-X","Left Basal Forebrain","Right Basal Forebrain","Right ACgG anterior cingulate gyrus","Left ACgG anterior cingulate gyrus","Right AIns anterior insula","Left AIns anterior insula","Right AOrG anterior orbital gyrus","Left AOrG anterior orbital gyrus","Right AnG angular gyrus","Left AnG angular gyrus","Right Calc calcarine cortex","Left Calc calcarine cortex","Right CO central operculum","Left CO central operculum","Right Cun cuneus","Left Cun cuneus","Right Ent entorhinal area","Left Ent entorhinal area","Right FO frontal operculum","Left FO frontal operculum","Right FRP frontal pole","Left FRP frontal pole","Right FuG fusiform gyrus","Left FuG fusiform gyrus","Right GRe gyrus rectus","Left GRe gyrus rectus","Right IOG inferior occipital gyrus","Left IOG inferior occipital gyrus","Right ITG inferior temporal gyrus","Left ITG inferior temporal gyrus","Right LiG lingual gyrus","Left LiG lingual gyrus","Right LOrG lateral orbital gyrus","Left LOrG lateral orbital gyrus","Right MCgG middle cingulate gyrus","Left MCgG middle cingulate gyrus","Right MFC medial frontal cortex","Left MFC medial frontal cortex","Right MFG middle frontal gyrus","Left MFG middle frontal gyrus","Right MOG middle occipital gyrus","Left MOG middle occipital gyrus","Right MOrG medial orbital gyrus","Left MOrG medial orbital gyrus","Right MPoG postcentral gyrus medial segment","Left MPoG postcentral gyrus medial segment","Right MPrG precentral gyrus medial segment","Left MPrG precentral gyrus medial segment","Right MSFG superior frontal gyrus medial segment","Left MSFG superior frontal gyrus medial segment","Right MTG middle temporal gyrus","Left MTG middle temporal gyrus","Right OCP occipital pole","Left OCP occipital pole","Right OFuG occipital fusiform gyrus","Left OFuG occipital fusiform gyrus","Right OpIFG opercular part of the inferior frontal gyrus","Left OpIFG opercular part of the inferior frontal gyrus","Right OrIFG orbital part of the inferior frontal gyrus","Left OrIFG orbital part of the inferior frontal gyrus","Right PCgG posterior cingulate gyrus","Left PCgG posterior cingulate gyrus","Right PCu precuneus","Left PCu precuneus","Right PHG parahippocampal gyrus","Left PHG parahippocampal gyrus","Right PIns posterior insula","Left PIns posterior insula","Right PO parietal operculum","Left PO parietal operculum","Right PoG postcentral gyrus","Left PoG postcentral gyrus","Right POrG posterior orbital gyrus","Left POrG posterior orbital gyrus","Right PP planum polare","Left PP planum polare","Right PrG precentral gyrus","Left PrG precentral gyrus","Right PT planum temporale","Left PT planum temporale","Right SCA subcallosal area","Left SCA subcallosal area","Right SFG superior frontal gyrus","Left SFG superior frontal gyrus","Right SMC supplementary motor cortex","Left SMC supplementary motor cortex","Right SMG supramarginal gyrus","Left SMG supramarginal gyrus","Right SOG superior occipital gyrus","Left SOG superior occipital gyrus","Right SPL superior parietal lobule","Left SPL superior parietal lobule","Right STG superior temporal gyrus","Left STG superior temporal gyrus","Right TMP temporal pole","Left TMP temporal pole","Right TrIFG triangular part of the inferior frontal gyrus","Left TrIFG triangular part of the inferior frontal gyrus","Right TTG transverse temporal gyrus","Left TTG transverse temporal gyrus"]

#if roi_id.count != roi_name.count
#  puts "ROI ID's and ROI Name arrays do not have the same number of elements!"
#  exit
#end

#roi_hash = Hash[roi_id.zip roi_name]

#roi_hash.each_pair do |id, name|
#  neuro_insert = "INSERT INTO `neuromorph_roi_names` (id, roi_name) values ('#{id}','#{name}');"
#  ActiveRecord::Base.connection.execute(neuro_insert)
#end



#roi_hash.each_pair {|id, name| ActiveRecord::Base.connection.execute("INSERT INTO `neuromorph_roi_names` (id, roi_name) values ('#{id}', '#{name}');")}





create_cbf = "CREATE TABLE `neuromorph_cbf_metrics` ( `id` INT NOT NULL AUTO_INCREMENT, `cg_asl_id` INT NOT NULL, "

#roi_name.each do |name|
#  cleanname = name.downcase.tr(" ","_")
#  create_sql << "`#{cleanname}` INT DEFAULT NULL, "
#end

#roi_name.each {|name| create_cbf << "`#{name.downcase.tr(" ", "_")}` DECIMAL(19,16) DEFAULT NULL, "} # this led to scientific notation

roi_name.each {|name| create_cbf << "`#{name.downcase.tr(" ", "_")}` DOUBLE DEFAULT NULL, "}

create_cbf << "PRIMARY KEY (`id`) );"

ActiveRecord::Base.connection.execute(create_cbf)

#CREATE TABLE `neuromorph_cbf_metrics` (
#    `id` INT NOT NULL AUTO_INCREMENT,
#    `cg_asl_id` INT DEFAULT NULL,
#    PRIMARY KEY (`id`)
#    );


create_vgm = "CREATE TABLE `neuromorph_vgm_metrics` ( `id` INT NOT NULL AUTO_INCREMENT, `cg_asl_id` INT NOT NULL, "

roi_name.each {|name| create_vgm << "`#{name.downcase.tr(" ", "_")}` INT DEFAULT NULL, "}

create_vgm << "PRIMARY KEY (`id`) );"

ActiveRecord::Base.connection.execute(create_vgm)



