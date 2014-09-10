class Merge < ActiveRecord::Base
  belongs_to :main_group,      class_name: "Group"
  belongs_to :secundary_group, class_name: "Group"

  after_create :change_group_status

  def change_group_status
    if type_merge # if merged
      main_group.update_attribute :status, true       # main group must be activated
      secundary_group.update_attribute :status, false # secundary group must be deactivated
    else
      main_group.update_attribute :status, true      # main group must be activated
      secundary_group.update_attribute :status, true # secundary group must be activated
    end
  end
end
