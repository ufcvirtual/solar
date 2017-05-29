class IpFake < ActiveRecord::Base
  belongs_to :ip_real
  attr_accessible :id, :ip_v4, :ip_v6, :_destroy
end
