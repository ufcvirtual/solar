class Merge < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :main_group, class_name: "Group"
  belongs_to :secundary_group, class_name: "Group"

  after_create :change_group_status

  def change_group_status
    main_group.update_attribute :status, true # main group must be activated
    secundary_group.update_attribute :status, not(type_merge) # secundary group must be deactivated if merge
  end
end
