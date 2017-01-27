class AssignmentFile < ActiveRecord::Base

  belongs_to :user
  belongs_to :academic_allocation_user

  has_one :academic_allocation, through: :academic_allocation_user, autosave: false
  has_one :assignment, through: :academic_allocation_user
  has_one :allocation_tag, through: :academic_allocation

  before_save :can_change?, if: 'merge.nil?'
  before_destroy :can_change?, :can_destroy?
  after_save :update_acu, on: :create
  after_destroy :update_acu

  validates :attachment_file_name, presence: true
  validates :academic_allocation_user_id, presence: true

  has_attached_file :attachment,
    path: ":rails_root/media/assignment/sent_assignment_files/:id_:basename.:extension",
    url: "/media/assignment/sent_assignment_files/:id_:basename.:extension"

  validates_attachment_size :attachment, less_than: 26.megabyte, message: ' '
  validates_attachment_content_type_in_black_list :attachment

  default_scope order: 'attachment_updated_at DESC'

  attr_accessor :merge

  def can_change?
    raise 'date_range' unless assignment.in_time?
  end

  def can_destroy?
    raise CanCan::AccessDenied unless user_id == User.current.try(:id)
    raise 'date_range' unless assignment.in_time?
  end

  def delete_with_dependents
    self.delete
  end

  private

    def update_acu
      unless academic_allocation_user_id.blank?
        if (academic_allocation_user.grade.blank? && academic_allocation_user.working_hours.blank?)
          if academic_allocation_user.assignment_files.empty? && academic_allocation_user.assignment_webconferences.where(final: true).empty?
            academic_allocation_user.status = AcademicAllocationUser::STATUS[:empty] 
          else
            academic_allocation_user.status = AcademicAllocationUser::STATUS[:sent] 
          end
        else
          academic_allocation_user.new_after_evaluation = true
        end
        academic_allocation_user.save(validate: false)
      end
    end

end
