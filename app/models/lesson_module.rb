class LessonModule < ActiveRecord::Base
  include AcademicTool

  GROUP_PERMISSION = OFFER_PERMISSION = true

  # a ordem das instrucoes importa para execucao
  before_destroy :verify_situation_module

  has_many :lessons, dependent: :destroy
  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :offers, through: :allocation_tags

  validates :name, presence: true

  accepts_nested_attributes_for :academic_allocations

  def verify_situation_module
   if lessons.count > 0  && academic_allocations.count > 1
     errors.add(:base, I18n.t(:cant_delete_shared, :scope => [:lesson_modules, :errors]))
     return false
   elsif is_default
     errors.add(:base, I18n.t(:cant_delete, :scope => [:lesson_modules, :errors]))
     return false
   end
  end

  def next_lesson_order
    lessons.maximum(:order).next rescue 1
  end

  def lessons_to_open(user = nil, list = false)
    user_is_admin_or_editor    = (user.admin? || user.editor?)
    user_responsible = user.nil? ? false : !(user.profiles_with_access_on('see_drafts', 'lessons', self.allocation_tags.map(&:related), true).empty?)

    lessons.order('lessons.order').collect{ |lesson|
      lesson_with_address = (list || !lesson.address.blank?)
      # if (lesson can open to show or list is true) or (is draft or will_open and is responsible) or user is admin
      lesson if ( user_is_admin_or_editor || (user_responsible && (lesson.is_draft? || lesson.will_open?) ) || (!lesson.is_draft? && ((list && !lesson.will_open?) || lesson.open_to_show?)) ) && lesson_with_address
    }.compact.uniq
  end

  def delete_with_academic_allocations
    academic_allocations.delete_all
    self.delete
  end

  def self.academic_allocations_by_ats(allocation_tags_ids, page: 1, per_page: 30)
    AcademicAllocation.select('DISTINCT ON (academic_tool_id) *').joins(:lesson_module)
      .where(allocation_tag_id: allocation_tags_ids)
      .order(:academic_tool_id)
      .paginate(page: page, per_page: per_page)
  end

  def self.to_select(allocation_tags_ids, user = nil, list = false)
    user_is_admin_or_editor    = user.nil? ? false : (user.admin? || user.editor?)
    user_responsible = user.nil? ? false : user.profiles_with_access_on('see_drafts', 'lessons', allocation_tags_ids, true).any?
    joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids }).order("id").delete_if { |lmodule|
      lessons               = lmodule.lessons
      has_open_lesson       = lessons.map(&:closed?).include?(false)

      only_responsible_sees = (lessons.collect{ |l| l if (l.will_open? || l.is_draft? || !(l.open_to_show? || list)) }.compact).size

      lessons.empty? || (
        # nao eh admin nem responsavel
        !user_is_admin_or_editor && (!user_responsible && (only_responsible_sees == lessons.size))
      ) || (
        !list && lessons.size == lessons.map{ |l| true if l.address.blank? }.compact.size
      ) || !(list || has_open_lesson)

    }.compact.uniq
  end

  def self.by_ats(allocation_tags_ids)
    joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids }).order('id').uniq
  end

  def approved_lessons(user_id)
    lessons(user_id).where(status: Lesson_Approved)
  end

  def allocation_tag_info
    [(groups.first.try(:offer) || offers.first).allocation_tag.info, groups.map(&:code).join(', ')].join(' - ')
  end

  def self.by_name_and_allocation_tags_ids(name, allocation_tags_ids)
    joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids }, name: name).uniq
  end

  def lessons(user_id = nil)
    if user_id.nil?
      Lesson.where(lesson_module_id: id)
    else
      Lesson.where(lesson_module_id: id).where('privacy = false OR user_id = ?', user_id)
    end
  end
end
