Factory.define :visit do |f|
  f.date(Date.today)
  f.sequence(:rmr) { |n| "rmr#{n}"}
  f.scan_procedures {[Factory.create(:scan_procedure)]}
end

Factory.define :scan_procedure do |f|
  f.sequence(:codename) { |n| "johnson.procedure#{n}"}
end

Factory.define :user do |f|
  f.sequence(:login) { |n| "foo#{n}" }
  f.password "foobar"
  f.password_confirmation { |u| u.password }
  f.sequence(:email) { |n| "foo#{n}@example.com" }
end

Factory.define :enrollment do |f|
  f.sequence(:enumber) { |n| "enumber00#{n}" }
  f.enroll_date
end

Factory.define :participant do |f|
  f.sequence(:access_id) { |n| "#{n}" }
  f.wrapnum
  f.gender
end

Factory.define :image_dataset do |f|
  f.series_description
  f.sequence(:scanned_file) {|n| "#{n}.dcm"}
  f.path "/path/to/dataset"
  f.rep_time 2000
  f.timestamp Date.today
end