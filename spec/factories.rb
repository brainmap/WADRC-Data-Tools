Factory.define :visit do |f|
  f.date Date.today
  f.sequence(:rmr) { |n| "rmr#{n}"}
  f.association :scan_procedure
end

Factory.define :scan_procedure do |f|
  f.sequence(:codename) { |n| "johnson.procedure#{n}"}
end
