# chartr_path = RAILS_ROOT + "/vendor/plugins/chartr"
chartr_path = Rails.root + "/vendor/plugins/chartr"

flotr = "flotr/release/prototype/flotr-0.2.0-test/flotr"

  # Files to be copied
ChartrFiles = ["#{chartr_path}/#{flotr}/flotr-min.js",
               "#{chartr_path}/#{flotr}/lib/canvastext.js",
               "#{chartr_path}/#{flotr}/lib/excanvas.js",
               "#{chartr_path}/#{flotr}/lib/base64.js",
               "#{chartr_path}/#{flotr}/lib/canvas2image.js"]
