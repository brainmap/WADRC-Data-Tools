=begin rdoc
Provides a mapping between series descriptions that are extracted from raw image
headers and some associated attributes.
=end
class SeriesDescriptionParameters
  #:stopdoc:
  SERIES_DESCRIPTIONS = {
    "3-P,Localizer" =>                  [ "3PlaneLoc", "anat", nil ],
    "gre field map rhrcctrl = 15" =>    [ "Fieldmap", "epan", nil ],
    "SAG EPI Test 1 2 3" =>             [ "EPITest", "epan", "sag" ],
    "3D IR AX T1 - NEW" =>              [ "T1_EFGRE3D", "anat", "ax" ],
    "AX T2 W FR FSE 1.7 skip 0.3" =>    [ "T2_FSE", "fse", "ax" ],
    "High Order Shim 28cm" =>           [ "Shim", "anat", nil ],
    "SAG gre field map rhrcctr =15" =>  [ "Fieldmap", "epan", "sag" ],
    "dti w/ card gate" =>               [ "DTI", "epan", nil ],
    "HOS Head coil" =>                  [ "3PlaneLoc", "anat", nil ],
    "Localizer" =>                      [ "3PlaneLoc", "anat", nil ],
    "F Map; rhrcctrl 15; te7, 10" =>    [ "Fieldmap", "epan", nil ],
    "SAG EPI TEST" =>                   [ "EPITest", "epan", "sag" ],
    "ASL CBF" =>                        [ "AlsopsASL", "anat", nil ],
    "DTI - prev 39 slices" =>           [ "DTI", "epan", nil ],
    "3D IR COR T1 - NEW" =>             [ "T1_EFGRE3D", "anat", "cor" ],
    "SAG T2 W FSE 1.7 skip 0.3" =>      [ "T2_FSE", "fse", "sag" ],
    "COR T2 W FSE 1.7 skip 0.3" =>      [ "T2_FSE", "fse", "cor" ],
    "3plane - hirez" =>                 [ "3PlaneLoc", "anat", nil ],
    "SAG gre field map rhrcctr =1?" =>  [ "Fieldmap", "epan", "sag" ],
    "SAG EPI Test 1 2 3" =>             [ "EPITest", "epan", "sag" ],
    "dti w/o card gate" =>              [ "DTI", "epan", nil ],
    "Ax Flair irFSE" =>                 [ "T1_Flair", "fse", "ax" ],
    "DTI" =>                            [ "DTI", "epan", nil ],
    "AX T2 Flair" =>                    [ "T2_Flair", "fse", "ax" ],
    "AX T2 FLAIR" =>                    [ "T2_Flair", "fse", "ax" ],
    "SAG EPI Snod" =>                   [ "fMRI_snod", "epan", "sag" ],
    "SAG EPI Resting" =>                [ "fMRI_rest", "epan", "sag" ],
    "SAG EPI Snod (141 x 2)" =>         [ "fMRI_snod", "epan", "sag" ],
    "DTI - 10 Dir 1.8mm" =>             [ "DTI", "epan", nil ],
    "F Map; rhrcctrl 15; te6, 9" =>     [ "Fieldmap", "epan", nil ],
    "ASSET CAL" =>                      [ "ASSET_Calibration", "epan", nil ],
    "SAG EPI Resting (180)" =>          [ "fMRI_rest", "epan", "sag" ],
    "Sag SMAPS" =>                      [ "smaps", "anat", "sag" ]
  }
  #:startdoc:

  # A string used to build nice file names for reconstructed data sets
  attr_reader :scan_type
  
  # Used as an argument to to3d, the AFNI command used to reconstruct a collection
  # of dicom files into a single nifti data set
  attr_reader :anat_type
  
  # The scan acquisition plane: axial, coronal, or sagittal
  attr_reader :acq_plane

=begin rdoc
Creates a new object based on a series description string.
The series description for an image is conveniently available as an attribute
of the RawImageFile class.

<i>Note that the series descriptions inside image headers sometimes have trailing</i>
<i>white space, the constructor here strips and chomps it.  Be advised of this behavior.</i>

<tt>sd = SeriesDescription.new('3D IR AX T1 - NEW')</tt>

<tt>sd.scan_type</tt>

<tt>=> "T1_EFGRE3D"</tt>

<tt>sd.anat_type</tt>

<tt>=> "anat"</tt>

<tt>sd.acq_plane</tt>

<tt>=> "axial"</tt>
=end
  def initialize(series_description)
    @series_description = series_description.strip.chomp
    raise IndexError if not SERIES_DESCRIPTIONS.has_key?(@series_description)
    @scan_type, @anat_type, @acq_plane = SERIES_DESCRIPTIONS[@series_description]
  end
end