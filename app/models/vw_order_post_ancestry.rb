class VwOrderPostAncestry < ActiveRecord::Base
    has_one :post, foreign_key: "start_of_ancestry"
end