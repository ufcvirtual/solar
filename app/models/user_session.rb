#class UserSession < ActiveRecord::Base #Authlogic::Session::Base
#
#  def to_key
#    new_record? ? nil : [ self.send(self.class.primary_key) ]
#  end
#
#end
