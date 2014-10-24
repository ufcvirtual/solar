class MenusContext < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :menu
  belongs_to :context
end
