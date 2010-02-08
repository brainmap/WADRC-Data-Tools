namespace :doc do
  desc "Draw a new railroad digram of models and controllers."
  task :diagrams => %w(diagram:models diagram:controllers)
  
  namespace :diagram do
    desc "Draw a new railroad diagram of Models"
    task :models do
      sh "railroad -i -l -a -m -M | dot -Tsvg | sed 's/font-size:14.00/font-size:11.00/g' > doc/models.svg"
    end

    desc "Draw a new railroad diagram of Controllers"
    task :controllers do
      sh "railroad -i -l -C | neato -Tsvg | sed 's/font-size:14.00/font-size:11.00/g' > doc/controllers.svg"
    end
  end
  
  desc "Show railroad diagram of Models"
  task :showmodels do
    sh "open doc/models.svg"
  end
  
  desc "Show railroad diagram of Controllers"
  task :showcontrollers do
    sh "open doc/controllers.svg"
  end
  

end