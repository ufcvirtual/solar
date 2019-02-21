class Changelog < ActiveRecord::Base
	# validates :description, presence: true
	validates :description, length: { maximum: 200 }
end
