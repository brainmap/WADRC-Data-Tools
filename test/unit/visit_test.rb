require 'test_helper'

Vrdd = Struct.new(:attributes_for_active_record, :scan_procedure_name, :datasets)
Rids = Struct.new(:attributes_for_active_record)

class VisitTest < Test::Unit::TestCase # < ActiveSupport::TestCase
  # Replace this with your real tests.
  def testVisitFixtures # "visit is in synch with other tables" do
    v = Visit.find_by_rmr("RMR123")
     assert_equal  "aaron", v.user.username
     assert_equal "Flair", v.protocol.name
     assert v.image_datasets.length > 0
  end
  
  def testVisitCreateOrUpdateFromMetamri    
    v = Vrdd.new
    v.scan_procedure_name = 'test.scan.procedure'
    v.attributes_for_active_record = { 
      :date => DateTime.now.to_s, 
      :rmr => 'test.rmr', 
      :path => 'test.path', 
      :scanner_source => 'test.scanner.source'
    }
    v.datasets = Array.new
    5.times do |n|
      v.datasets << Rids.new({
        :rmr => 'test.rmr',
        :series_description => "test.series.description-#{n}",
        :path => "test.dir-#{n}",
        :timestamp => DateTime.now.to_s,
        :glob => "test.glob-#{n}",
        :rep_time => n,
        :bold_reps => n,
        :slices_per_volume => n,
        :scanned_file => "test.scanned.file-#{n}" })
    end
    Visit.create_or_update_by_metamri(v)
  end
end
