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

  validate :unique_code_on_offer, unless: 'offer_id.nil? || code.nil? || !code_changed?'

  validates_length_of :code, maximum: 40

  validates :digital_class_directory_id, uniqueness: true, on: :update, unless: 'digital_class_directory_id.blank?'

  after_save :update_digital_class, if: "code_changed?"

  def order
   'groups.status, groups.code'
  end 

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
      group: code
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

  def self.management_groups
    codes_file_uab = YAML::load(File.open("config/global.yml"))[Rails.env.to_s]["uab_courses"]["code"]
    code_courses_uab = codes_file_uab.split(";")

    groups_to_manage = []
    acs_offers = []

    code_courses_uab.each do |code_course|

      course = Course.find_by(code: code_course)
      offers = Offer.where(course_id: course.id) unless course.blank?
      groups = Group.where(offer_id: offers)

      allocation_tags = AllocationTag.where(group_id: groups)
      
      acs_offers = AcademicAllocation.where(allocation_tag_id: AllocationTag.where(offer_id: offers).where(group_id: nil)).where(academic_tool_type: 'LessonModule')

      allocation_tags.each do |allocation_tag|
        academic_allocations = AcademicAllocation.where(allocation_tag_id: allocation_tag.id)

        group = allocation_tag.group
        offer = group.offer

        academic_allocations.each do |academic_allocation|
          academic_tool = academic_allocation.academic_tool

          if academic_allocation.academic_tool_type == 'LessonModule'
           
            lessons = Lesson.where(lesson_module_id: academic_tool.id)

            lessons.flatten.each do |lesson|
              
              if lesson.schedule.start_date <= Date.current && lesson.schedule.start_date >= offer.semester.offer_schedule.start_date
                groups_to_manage << group unless groups_to_manage.include? group
                break
              end

            end

          end

        end
      
      end

    end

    unless groups_to_manage.blank?
      groups_to_manage.uniq.each do |group|
        verify_management(group.allocation_tag)
      end
    end

    unless acs_offers.blank?
      acs_offers.each do |academic_allocation_offer|
        verify_management(academic_allocation_offer.allocation_tag)
      end
    end

  end

  def self.verify_management(allocation_tag)

      academic_allocations = AcademicAllocation.where(allocation_tag_id: allocation_tag.id)

      at = AllocationTag.find(allocation_tag.id)

      total_hours_of_curriculum_unit = at.group.nil? ? at.offer.curriculum_unit.working_hours : at.group.offer.curriculum_unit.working_hours
      quantity_activities = 0
      quantity_used_hours = 0
      
      acad_alloc_not_event = []
      acad_alloc_event = []

      acad_alloc_to_save = []

      academic_allocations.select!{|ac| ac.evaluative == false || ac.frequency == false }

      academic_allocations.each do |academic_allocation|
        academic_tool = academic_allocation.academic_tool
        puts "Entrou aqui 2"
        if academic_allocation.academic_tool_type == 'ScheduleEvent' #&& academic_tool.integrated == true
          
          if academic_tool.type_event == Presential_Test # eventos tipo 1 ou 2 chamada
            academic_allocation.evaluative = true
            academic_allocation.final_weight = 60
            academic_allocation.frequency = true
            academic_allocation.max_working_hours = BigDecimal.new(2)
  
            if academic_tool.title == "Prova Presencial: AF - 1ª chamada" || academic_tool.title == "Prova Presencial: AF - 2ª chamada" # se Avaliação Final
              academic_allocation.final_exam = true
              academic_allocation.frequency = false
              academic_allocation.max_working_hours = BigDecimal.new(0)
            end
  
            if academic_tool.title == "Prova Presencial: AP - 2ª chamada" || academic_tool.title == "Prova Presencial: AF - 2ª chamada" # se 2 chamada, então deve ser equivalente a 1 chamada
                                    
              equivalent = ScheduleEvent.joins(:academic_allocations).where(title: academic_tool.title.sub("2", "1"), academic_allocations: {equivalent_academic_allocation_id: nil, allocation_tag_id: allocation_tag_id.to_i})
              
              unless equivalent.blank?
                academic_allocation.equivalent_academic_allocation_id = equivalent[0].academic_allocations[0].id
                academic_allocation.max_working_hours = BigDecimal.new(0)
              end
              
            end
            
          end
          
          unless [Presential_Test, Recess, Holiday, Other].include?(academic_tool.type_event) # demais eventos exceto: recesso, feriado e outros
            academic_allocation.frequency = true
            academic_allocation.max_working_hours = BigDecimal.new(2)
          end

          acad_alloc_event << academic_allocation
  
        else # atividades que não são eventos
          
          unless academic_allocation.academic_tool_type == 'LessonModule' && academic_allocation.final_weight == 100 && academic_allocation.max_working_hours.to_i == 1 # LessonModule criado por padrão
                    
            academic_allocation.evaluative = true
            academic_allocation.final_weight = 40
            academic_allocation.frequency = true
            quantity_activities += 1
    
            acad_alloc_not_event << academic_allocation
          end

        end

      end

      acad_alloc_event.each do |event|
        if event.final_exam == false || event.equivalent_academic_allocation_id.nil?
          quantity_used_hours += event.max_working_hours.to_i
        end
      end
      
      remaining_hours = total_hours_of_curriculum_unit - quantity_used_hours
      resto = remaining_hours % quantity_activities rescue 0
      hours_per_activity = remaining_hours / quantity_activities rescue 0
            
      acad_alloc_not_event.each{ |ac_all| ac_all.max_working_hours = BigDecimal.new(hours_per_activity)}

      if resto != 0
        acad_alloc_not_event.last.max_working_hours += BigDecimal.new(resto)
      end

      acad_alloc_to_save.concat(acad_alloc_event.sort_by!{|all| all.academic_tool.title}).concat(acad_alloc_not_event)

      unless acad_alloc_to_save.blank?
        ActiveRecord::Base.transaction do
          acad_alloc_to_save.each do |acad_alloc|
            acad_alloc.save!
          end
        end
      end

    

  end

  private

    def unique_code_on_offer
      errors.add(:code, I18n.t(:taken, scope: [:activerecord, :errors, :messages])) if Group.where(offer_id: offer_id).where("lower(code) = '#{code.downcase}'").any?
    end

end
