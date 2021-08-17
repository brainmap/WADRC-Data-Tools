class AppointmentTubetype < ActiveRecord::Base

  # This class (particularly its match_lookup_ref method) is a workaround to allow the
  # tubetypes to be searchable from dropdowns throughout the Panda, as well as useable
  # from the console. We did have an accessory table with tubetypes that this was once 
  # referring to, but that's another ancillary lookup_refs table that we don't need.

  # before_validation :match_lookup_ref

  # after_commit :match_lookup_ref, if: proc { |object| object.previous_changes.include?('lookup_ref') }

  # attr_accessor :tubetype_id

  belongs_to :appointment
  belongs_to :lookup_ref

  def lookup_ref=(val)
    update(lookup_ref: val)
    write_attribute(:tubetype_id, lookup_ref.ref_value.to_i)

  end 

end