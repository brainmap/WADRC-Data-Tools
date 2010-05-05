class Help < ActiveRecord::Base
  acts_as_taggable
  validates_presence_of :question, :answer
end