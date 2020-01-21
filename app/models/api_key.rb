class ApiKey < ActiveRecord::Base
  
  belongs_to :user

  before_create :generate_access_token

  private
  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while self.class.exists?(access_token: access_token)
  end
end


# create table `api_keys` (
# `id` int(11) NOT NULL AUTO_INCREMENT,
# `user_id` int(11) DEFAULT NULL,
# `access_token` varchar(255) DEFAULT NULL,
# PRIMARY KEY (`id`),
# UNIQUE KEY `access_token_idx` (`access_token`),
# KEY `user_id` (`user_id`));