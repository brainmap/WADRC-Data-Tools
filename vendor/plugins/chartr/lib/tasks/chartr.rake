root = File.dirname(__FILE__) + "/../../"

require root + "lib/chartrfiles"

namespace :chartr do
  desc "Compress JS files into chartr.js"
  task :singlefile do
    FileUtils.cd('public/javascripts') do
      output = ""
      output << File.read('prototype.js')
      ChartrFiles.each do |f|
        output << File.read(f)
      end
      File.open('/tmp/chartr.js', 'w') do |f|
        f.write(output)
    end
    end
    
    `java -jar #{root}./flotr/yuicompressor-2.4.2.jar  /tmp/chartr.js > public/javascripts/chartr.js`
  end
end
