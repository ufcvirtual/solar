class Group < ActiveRecord::Base
  include Taggable

  #default_scope order: 'groups.status, groups.code'

  belongs_to :offer

  has_one :curriculum_unit,      through: :offer
  has_one :course,               through: :offer
  has_one :semester,             through: :offer
  has_one :curriculum_unit_type, through: :curriculum_unit

  has_many :academic_allocations, through: :allocation_tag
  has_many :lesson_modules,       through: :academic_allocations, source: :academic_tool, source_type: 'LessonModule'
  has_many :assignments,          through: :academic_allocations, source: :academic_tool, source_type: 'Assignment'
  has_many :merges_as_main, class_name: 'Merge', foreign_key: 'main_group_id', dependent: :destroy
  has_many :merges_as_secundary, class_name: 'Merge', foreign_key: 'secundary_group_id', dependent: :destroy
  has_many :related_taggables

  after_create :set_default_lesson_module

  validates :code, :offer_id, presence: true

  validate :unique_code_on_offer_by_name, unless: 'offer_id.nil? || code.nil? || !code_changed?'
  validate :unique_name_on_offer, unless: 'offer_id.nil? || name.blank? || !name_changed?'

  validates :code, length: { maximum: 40 }
  validates :name, :location, length: { maximum: 100 }

  validates :digital_class_directory_id, uniqueness: true, on: :update, unless: 'digital_class_directory_id.blank?'

  before_save :set_empty_name, if: 'name.blank?'

  validate :name_mandatory_if_distant, if: 'name.blank?'

  after_save :update_digital_class, if: "code_changed?"

  validate :block_fields_if_integrated, if: 'integrated && api.blank?'

  def order
   'groups.status, groups.code'
  end

  attr_accessor :api

  def code_semester
    "#{code} - #{offer.semester.name}"
  end

  def set_default_lesson_module
    create_default_lesson_module(I18n.t(:general_of_group, scope: :lesson_modules))
  end

  # recupera os participantes com perfil de estudante
  def students_participants
    AllocationTag.get_participants(allocation_tag.id, { students: true })
  end

  def students_allocations
    Allocation.joins(:profile).where("cast( profiles.types & '#{Profile_Type_Student}' as boolean )")
      .where(status: Allocation_Activated, allocation_tag_id: allocation_tag.related).uniq(:user_id)
  end

  def any_lower_association?
    false
  end

  def as_label
    [offer.semester.name, code, offer.curriculum_unit.try(:name)].join('|')
  end

  def detailed_info
    {
      curriculum_unit_type: offer.curriculum_unit_type.try(:description) || '',
      curriculum_unit_type_id: offer.curriculum_unit_type.try(:id) || '',
      course: offer.course.try(:name) || '',
      curriculum_unit: offer.curriculum_unit.try(:name) || '',
      semester: offer.semester.name,
      group: get_code_name
    }
  end

  def request_enrollment(user_id)
    result = { success: [], error: [] }
    allocation = Allocation.where(user_id: user_id, allocation_tag_id: allocation_tag.id, profile_id: Profile.student_profile).first_or_initialize

    enroll_period = offer.enrollment_period
    if Date.today.between?(enroll_period.first, enroll_period.last) # verify enrollment period
      allocation.status = Allocation_Pending
      allocation.save
      result[:success] << allocation
    else
      allocation.errors.add(:base, I18n.t('allocations.request.error.enroll'))
      result[:error] << allocation
    end

    result
  end

  def get_accesses(user_id = nil)
    query = []
    query << "user_id = #{user_id}" unless user_id.nil?
    query << "allocation_tags.group_id = #{id}"
    query << "log_type = #{LogAccess::TYPE[:group_access]}"

    LogAccess.joins(:allocation_tag).joins('LEFT JOIN merges ON merges.main_group_id = allocation_tags.group_id OR merges.secundary_group_id = allocation_tags.group_id').where(query.join(' AND ')).uniq
  end

  def verify_or_create_at_digital_class(available=nil)
    return digital_class_directory_id unless digital_class_directory_id.nil?
    return false unless (available.nil? ? DigitalClass.available? : available)
    directory = DigitalClass.call('directories', params_to_directory, [], :post)
    self.digital_class_directory_id = directory['id']
    self.save(validate: false)
    return digital_class_directory_id
  rescue => error
    # if error 400, ja existe la
  end

  def get_code_name
    # show groups name with code only if uab (distance)
    (name.blank? || curriculum_unit.blank? || curriculum_unit.curriculum_unit_type_id != 2 || name == code) ? code : "#{code} (#{name})"
  end

  def params_to_directory
    { name: code, discipline: curriculum_unit.code_name, course: course.code_name, tags: [semester.name, curriculum_unit_type.description].join(',') }
  end

  def self.get_directory_by_groups(group_id)
    Group.find(group_id).digital_class_directory_id
  end

  def self.get_group_from_directory(diretory_id)
    Group.where('digital_class_directory_id = ?', diretory_id)
  end

  def self.get_group_from_lesson(lesson)
    directories_ids = []
    lesson['directories'].each do |d|
      directories_ids << d['id']
    end
    groups = Group.where({digital_class_directory_id: directories_ids})
  end

  def self.verify_or_create_at_digital_class(groups)
    groups.collect{ |group| group.verify_or_create_at_digital_class }
  end

  trigger.after(:update).of(:offer_id, :status) do
    <<-SQL
      UPDATE related_taggables
         SET group_status = NEW.status,
             offer_id = NEW.offer_id,
             offer_at_id = (SELECT id FROM allocation_tags WHERE offer_id = NEW.offer_id)
       WHERE group_id = OLD.id;
    SQL
  end

  private

    def unique_code_on_offer_by_name
      groups = Group.where(offer_id: offer_id)
      if name.blank?
        errors.add(:code, I18n.t(:taken, scope: [:activerecord, :errors, :messages])) if groups.where("lower(code) = '#{code.downcase}' AND (name IS NULL OR name = '')").any?
      else
        errors.add(:code, I18n.t(:taken, scope: [:activerecord, :errors, :messages])) if groups.where("lower(code) = '#{code.downcase}' AND lower(name) = '#{name.downcase}'").any?
      end
    end

    def unique_name_on_offer
      errors.add(:name, I18n.t(:taken, scope: [:activerecord, :errors, :messages])) if Group.where(offer_id: offer_id).where("lower(name) = '#{name.downcase}'").any?
    end

    # garantees that name will be nil when blank
    def set_empty_name
      self.name = nil
    end

    def name_mandatory_if_distant
      errors.add(:name, I18n.t(:blank, scope: [:activerecord, :errors, :messages])) if offer.try(:curriculum_unit).try(:curriculum_unit_type_id) == 2
    end

    def block_fields_if_integrated
      errors.add(:name, I18n.t('groups.error.blocked')) if name_changed? && !(name_was.blank? && name.blank?)
      errors.add(:code, I18n.t('groups.error.blocked')) if code_changed? && !(code_was.blank? && code.blank?)
      errors.add(:location, I18n.t('groups.error.blocked')) if location_changed? && !(location_was.blank? && location.blank?)
    end

end
