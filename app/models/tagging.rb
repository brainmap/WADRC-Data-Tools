class Tagging < ActiveRecord::Base
  belongs_to :help
  belongs_to :tag
end
