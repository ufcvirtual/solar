class GroupAssignment < ActiveRecord::Base

  before_destroy :can_destroy? # deve ficar antes das associacoes

  belongs_to :academic_allocation, -> { where academic_tool_type: 'Assignment' }

  has_one :academic_allocation_user, dependent: :destroy

  has_many :group_participants, dependent: :delete_all
  has_many :users, through: :group_participants

  validates :group_name, presence: true, length: { maximum: 20 }

  validate :define_name
  validate :unique_group_name

  before_save :verify_offer, if: 'merge.nil?'

  attr_accessor :merge

  def can_remove?
    (academic_allocation_user.nil? || (academic_allocation_user.assignment_files.empty? && academic_allocation_user.grade.blank?))
  end

  def assignment
    Assignment.find(academic_allocation.academic_tool_id)
  end

  def evaluated?
    !(academic_allocation_user.nil? || (academic_allocation_user.grade.blank? && academic_allocation_user.working_hours.blank?))
  end

  def user_in_group?(user_id)
    group_participants.map(&:user_id).include? user_id.to_i
  end

  def can_destroy?
    raise "cant_remove" unless can_remove?
  end

  def copy(to_ac_id)
    new_group = GroupAssignment.where(group_name: group_name, academic_allocation_id: to_ac_id).first_or_create!
    copy_participants(new_group.id, to_ac_id)
  end

  def copy_participants(group_id, ac_id)
    all_participants = GroupAssignment.where(academic_allocation_id: ac_id).map(&:users).flatten.map(&:id)
    group_participants.each do |participant|
      GroupParticipant.where(user_id: participant.user_id, group_assignment_id: group_id).first_or_create! unless all_participants.include? participant.user_id
    end
  end

  def delete_with_dependents
    group_participants.delete_all
    self.delete
  end

  def self.by_user_id(user_id, academic_allocation_id)
    joins(:group_participants).where(academic_allocation_id: academic_allocation_id, group_participants: {user_id: user_id}).first
  end

  def self.split_students_in_groups
    assignments_in_group = Assignment.joins(:schedule).where(type_assignment: 1, schedules: {start_date: Date.current})
    
    assignments_in_group.each do |assignment_group|

      assignment_group.academic_allocations.each do |academic_allocation|
        alloc_tag_id = academic_allocation.allocation_tag_id

        students_without_group = academic_allocation.academic_tool.students_without_groups(alloc_tag_id)
        group_quantity_students = academic_allocation.allocation_tag.group.students_participants.count

        unless students_without_group.blank?
          
          responsibles_emails = User.joins(:allocations, :profiles).where(allocations: {allocation_tag_id: alloc_tag_id}).where(profiles: {types: 2}).uniq.map{|user| user.email}
          students_ids = students_without_group.pluck(:id).shuffle
          students_groups = []

          groups_assignment_division = {}
          Struct.new('Group_Object',:group_name, :students)

          if students_without_group.length == group_quantity_students || students_without_group.length == (group_quantity_students / 2) #se todos os alunos estão sem grupo ou metade possui grupo
            students_groups = students_ids.in_groups_of(3, false) # divisão em grupos de 3
            
             if students_ids.length % 3 == 1 # caso sobrar um estudante sem grupo, inserir no último grupo
              students_groups[students_groups.length-2] << students_groups[students_groups.length-1][0]
              students_groups.pop
             end
          end

          if (group_quantity_students - students_without_group.length) > (group_quantity_students / 2) #Se mais da metade possui grupos, pegar a média de alunos nesses grupos para dividir os novos grupos.
            average = calculate_average_students_per_group(academic_allocation.academic_tool.id, alloc_tag_id)

            students_remains_quantity = group_quantity_students % average.to_i
            
            if students_remains_quantity == 0 #quantidade exata para formar um grupo
              students_groups = students_ids.in_groups_of(average.to_i, false)
            end

            if students_remains_quantity != 0 && students_ids.length > average.to_i
              students_groups = students_ids.in_groups_of(average.to_i, false)

              remains = students_groups.pop 

              if remains.length <= (average.to_i/2)
                groups_assignments = GroupAssignment.where(academic_allocation_id: academic_allocation.id)

                ActiveRecord::Base.transaction do

                  remains.each_with_index do |student_id, index|
                    GroupParticipant.create!(group_assignment_id: groups_assignments[index].id, user_id: student_id)
                    student_names_per_group = User.where(id: GroupParticipant.where(group_assignment_id: groups_assignments[index].id).map{|gp| gp.user_id}).pluck(:name)
                  
                    struct = Struct::Group_Object.new(groups_assignments[index].group_name, student_names_per_group)
                    key_assignment = "#{groups_assignments[index].assignment.name}_#{academic_allocation.id}"

                    groups_assignment_division[key_assignment] ||= []
                    groups_assignment_division[key_assignment] << struct
                  end
                end 

              end

            end

            if students_remains_quantity != 0 && students_ids.length <= (average.to_i/2)
              groups_assignments = GroupAssignment.where(academic_allocation_id: academic_allocation.id)

              ActiveRecord::Base.transaction do

                students_ids.each_with_index do |student_id, index|
                  GroupParticipant.create!(group_assignment_id: groups_assignments[index].id, user_id: student_id)
                  student_names_group = User.where(id: GroupParticipant.where(group_assignment_id: groups_assignments[index].id).map{|gp| gp.user_id}).pluck(:name)
                
                  struct = Struct::Group_Object.new(groups_assignments[index].group_name, student_names_group)
                  key_assignment = "#{groups_assignments[index].assignment.name}_#{academic_allocation.id}"

                  groups_assignment_division[key_assignment] ||= []
                  groups_assignment_division[key_assignment] << struct
                end
              end
              
            end

          end
          
          students_groups.each_with_index do |groups, index|            
            student_names_by_group = []

            ActiveRecord::Base.transaction do
              group_assignment = GroupAssignment.create!(group_name: "GRUPO #{index+1}", academic_allocation_id: academic_allocation.id)
              
              groups.each do |student_id|
                gp = GroupParticipant.create!(group_assignment_id: group_assignment.id, user_id: student_id)
                student_names_by_group << gp.user.name
              end
              
              struct = Struct::Group_Object.new(group_assignment.group_name, student_names_by_group)
              key_assignment = "#{group_assignment.assignment.name}_#{academic_allocation.id}"

              groups_assignment_division[key_assignment] ||= []
              groups_assignment_division[key_assignment] << struct
            end

          end

          unless groups_assignment_division.blank?
            Notifier.send_mail(responsibles_emails, "Divisão Automática de trabalhos em grupo", email_template(groups_assignment_division), []).deliver
          end          

        end

      end    
    end
    
  end
  
  private

    def self.calculate_average_students_per_group(academic_tool_id, allocation_tag_id)
      sql = "SELECT AVG(quantity)
             FROM(
                    SELECT DISTINCT gp.group_name, COUNT(gpa) as quantity
                    FROM group_assignments gp
                    INNER JOIN academic_allocations al ON al.id = gp.academic_allocation_id
                    INNER JOIN group_participants gpa ON gpa.group_assignment_id = gp.id
                    WHERE al.academic_tool_id = #{academic_tool_id}
                    AND al.allocation_tag_id = #{allocation_tag_id}
                    GROUP BY gp.group_name
                ) 
              AS INNER_QUERY"
              
      ActiveRecord::Base.connection.exec_query(sql).rows.flatten[0]
    end

    def unique_group_name
      groups_with_same_name = GroupAssignment.find_all_by_academic_allocation_id_and_group_name(academic_allocation_id, group_name)
      errors.add(:group_name, I18n.t("group_assignments.error.unique_name")) if (new_record? or group_name_changed?) and groups_with_same_name.size > 0
    end

    def define_name
      if group_name == I18n.t("group_assignments.new.new_group_name")
        count, group = 1, GroupAssignment.where({group_name: "#{I18n.t("group_assignments.new.new_group_name")}", academic_allocation_id: academic_allocation_id}).first_or_initialize

        until group.new_record?
          group = GroupAssignment.where({group_name: "#{I18n.t("group_assignments.new.new_group_name")} #{count}", academic_allocation_id: academic_allocation_id}).first_or_initialize
          count += 1
        end

        self.group_name = group.group_name
      end
    end

    def verify_offer
      offer = academic_allocation.allocation_tag.offers.first
      raise 'offer_end'  if offer.end_date < Date.current
      # raise 'offer_start' if offer.start_date > Date.current
    end

    def self.msg_template(assignment_groups)
      html = ""

      assignment_groups.each do |key, value|
        assignment_key = key[-key.length..key.index("_")-1]
        html = "<p>O trabalho #{assignment_key} inicia hoje, alunos sem grupos foram dividos ou inseridos em outros grupos de forma automática do seguinte modo:</p>"

        value.each do |object|
          html << "<p>#{object.group_name}: "

          object.students.each do |student_name|
            html << "#{student_name}, "
          end

          html = html[0..html.length-3]
          html << "</p>"
        end

      end
      html
    end

    def self.email_template(assignment_groups)
      %{#{msg_template(assignment_groups)}}
    end

end
