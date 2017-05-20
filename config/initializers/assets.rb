           
  # for 3.2 to 4   
Rails.application.config.assets.precompile += %w( jquery.js )  
Rails.application.config.assets.precompile += %w( jquery_ujs.js )
Rails.application.config.assets.precompile += %w( rails.js )
Rails.application.config.assets.precompile += %w( jquery.min.js )