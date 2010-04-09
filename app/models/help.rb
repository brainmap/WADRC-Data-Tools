class Help < ActiveRecord::Base
   validates_presence_of :question, :answer
end
