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

  validates :name, presence: true, length: { maximum: 100 }

  accepts_nested_attributes_for :academic_allocations

  def verify_situation_module
   if lessons.count > 0  && academic_allocations.count > 1
     errors.add(:base, I18n.t(:cant_delete_shared, :scope => [:lesson_modules, :errors]))
     return false
   elsif is_default
     errors.add(:base, I18n.t(:cant_delete, :scope => [:lesson_modules, :errors]))
     return false
   end
   return true
  end

  def next_lesson_order
    lessons.maximum(:order).next rescue 1
  end

  def lessons_to_open(user = nil, list = false)
    user_is_admin_or_editor    = (user.admin? || user.editor?)
    user_responsible = user.nil? ? false : !(user.profiles_with_access_on('see_drafts', 'lessons', self.allocation_tags.map(&:related), true).empty?)

    lessons.eager_load(:schedule).order('lessons.order').collect{ |lesson|
      lesson_with_address = (list || !lesson.address.blank?)
      # if (lesson can open to show or list is true) or (is draft or will_open and is responsible) or user is admin

      lesson if ( user_is_admin_or_editor || (user_responsible && (lesson.is_draft? || lesson.will_open? || lesson.closed?) ) || (!lesson.is_draft? && ((list && (!lesson.will_open? || lesson.closed?)) || lesson.open_to_show?)) ) && lesson_with_address
    }.compact.uniq
  end

  def delete_with_academic_allocations
    academic_allocations.each do |ac|
      ac.force = true
      ac.delete
    end
    self.delete
  end

  def self.academic_allocations_by_ats(allocation_tags_ids, page: 1, per_page: 30)
    AcademicAllocation.select('DISTINCT ON (academic_allocations.academic_tool_id) *').joins(:lesson_module)
      .where(allocation_tag_id: allocation_tags_ids)
      .order(:academic_tool_id)
      .paginate(page: page, per_page: per_page)
  end

  def self.to_select(allocation_tags_ids, user = nil, list = false)
    user_is_admin_or_editor    = user.nil? ? false : (user.admin? || user.editor?)
    user_responsible = user.nil? ? false : user.profiles_with_access_on('see_drafts', 'lessons', allocation_tags_ids, true).any?

    joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids }).order("lesson_modules.name").to_a.delete_if { |lmodule|
      lessons               = lmodule.lessons.eager_load(:schedule)
      has_open_lesson       = lessons.map(&:closed?).include?(false)
      only_responsible_sees = (lessons.collect{ |l| l if (l.will_open? || l.is_draft? || !(l.open_to_show? || list) || (!list && l.closed?)) }.compact).size

      lessons.empty? || (
        # nao eh admin nem responsavel
        !user_is_admin_or_editor && (!user_responsible && (only_responsible_sees == lessons.size) )
      ) || (
        !list && lessons.size == lessons.map{ |l| true if l.address.blank? }.compact.size
      ) || (!user_responsible && !(list || has_open_lesson))
    }.compact.uniq
  end

  def self.by_ats(allocation_tags_ids)
    joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids }).order('id').uniq
  end

  def approved_lessons(user_id)
    lessons(user_id).where(status: Lesson_Approved).order('lessons.order ASC')
  end

  def allocation_tag_info
    [(groups.first.try(:offer) || offers.first).allocation_tag.info, groups.map(&:code).join(', ')].join(' - ')
  end

  def self.by_name_and_allocation_tags_ids(name, allocation_tags_ids)
    joins(:academic_allocations).where(academic_allocations: { allocation_tag_id: allocation_tags_ids }, name: name).uniq
  end

  def lessons(user_id = nil)
    if user_id.nil?
      Lesson.where(lesson_module_id: id).order('lessons.order ASC')
    else
      Lesson.where(lesson_module_id: id).where('privacy = false OR user_id = ?', user_id).order('lessons.order ASC')
    end
  end

  def copy_dependencies_from(module_to_copy)
    unless module_to_copy.lessons.empty?
      module_to_copy.lessons.each do |lesson_to_copy|
        lesson = Lesson.create! lesson_to_copy.attributes.merge({ lesson_module_id: self.id, imported_from_id: lesson_to_copy.id, receive_updates: false })
      end
    end
  end
end
