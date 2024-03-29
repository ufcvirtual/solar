class GroupAssignment < ActiveRecord::Base
  #include APILog

  before_destroy :can_destroy? # deve ficar antes das associacoes

  belongs_to :academic_allocation, -> { where academic_tool_type: 'Assignment' }

  has_one :academic_allocation_user, dependent: :destroy

  has_many :group_participants, dependent: :delete_all
  has_many :users, through: :group_participants

  validates :group_name, presence: true, length: { maximum: 20 }

  validate :define_name
  validate :unique_group_name

  before_save :verify_offer, if: -> {merge.nil?}

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

  def self.send_email_one_week_before_start_assignment_in_group(assignment_id = nil)
    unless assignment_id.nil?
      assignments_in_group = Assignment.includes(:schedule).where(type_assignment: Assignment_Type_Group).where('schedules.start_date > ? AND schedules.start_date < ?', Date.current, Date.current + 6).where(id: assignment_id).references(:schedules)
      puts assignments_in_group
    else
      assignments_in_group = Assignment.includes(:schedule).where(type_assignment: Assignment_Type_Group).where('schedules.start_date = ?', Date.current + 6.days).references(:schedules)
    end
    
    assignments_in_group.each do |assignment_group|

      assignment_group.academic_allocations.each do |academic_allocation|
        alloc_tag_ids = AllocationTag.find(academic_allocation.allocation_tag_id).related
        
        responsibles_emails = User.joins(:profiles, :allocations)
                                  .where(allocations: {allocation_tag_id: alloc_tag_ids})
                                  .where(profiles: {id: Profile.with_access_on(:automatic_email_group_assignment_division, :emails)})
                                  .uniq.map{|user| user.email}
        
        Job.send_mass_email(responsibles_emails, I18n.t("group_assignments.alert_create_assignment_group_email"), "#{I18n.t('group_assignments.automatic_one_week_before_email_split_group', assignment_group_name: assignment_group.name)}", [], nil, false)
      end
    end
  end

  def self.split_students_in_groups(assignment_id = nil)

    unless assignment_id.nil?
      assignments_in_group = Assignment.includes(:schedule).where(type_assignment: Assignment_Type_Group, schedules: {start_date: Date.current}).where(id: assignment_id).references(:schedules)
    else
      assignments_in_group = Assignment.includes(:schedule).where(type_assignment: Assignment_Type_Group, schedules: {start_date: Date.current}).references(:schedules)
    end

    assignments_in_group.each do |assignment_group|

      assignment_group.academic_allocations.each do |academic_allocation|
        alloc_tag_ids = AllocationTag.find(academic_allocation.allocation_tag_id).related #verificar se realmente o related é necessário
        students_without_group = academic_allocation.academic_tool.students_without_groups(alloc_tag_ids)

        unless students_without_group.blank?
          responsibles_emails = User.joins(:profiles, :allocations)
                                    .where(allocations: {allocation_tag_id: alloc_tag_ids})
                                    .where(profiles: {id: Profile.with_access_on(:automatic_email_group_assignment_division, :emails)})
                                    .uniq.map{|user| user.email}

          students_groups = []
          Struct.new('Group_Object', :group_name, :students)
          groups_assignment_division, students_groups = GroupAssignment.get_groups_assignment_division(students_without_group, academic_allocation, alloc_tag_ids, students_groups)
          groups_assignment_division, students_groups = GroupAssignment.add_student_in_groups_assignment_division(students_groups, groups_assignment_division, academic_allocation)

          unless groups_assignment_division.blank?
            Job.send_mass_email(responsibles_emails, I18n.t("group_assignments.automatic_split_group_jobs"), email_template(groups_assignment_division), [], nil, false)
          end

        end

      end

    end

  end

  private

    def self.add_student_in_groups_assignment_division(students_groups, groups_assignment_division, academic_allocation)
      students_groups.each_with_index do |groups, index|
        student_names_by_group = []

        ActiveRecord::Base.transaction do
          name_group = "GRUPO #{index+1}"
          all_groups = GroupAssignment.where(academic_allocation_id: academic_allocation.id)
          unless all_groups.blank?
            all_group_names = all_groups.map{|g| g.group_name}
            if all_group_names.include? name_group
              number_group_array = []
              all_group_names.each{|gname| number_group_array << gname.split(" ")[1].to_i}
              name_group = "GRUPO #{number_group_array.max + 1}"
            end
          end
          group_assignment = GroupAssignment.create!(group_name: name_group, academic_allocation_id: academic_allocation.id)
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
      return groups_assignment_division, students_groups
    end

    def self.get_groups_assignment_division(students_without_group, academic_allocation, alloc_tag_id, students_groups)

      total_quantity_students = academic_allocation.allocation_tag.group.students_participants.count

      students_ids = students_without_group.pluck(:id).shuffle
      groups_assignment_division = {}

      if students_without_group.length == total_quantity_students #se todos os alunos estão sem grupo
        students_groups = students_without_group.length == 4 && total_quantity_students == 4 ?
                            GroupAssignment.split_students_in_groups_of_standard_number(2, students_groups, students_ids) :
                            GroupAssignment.split_students_in_groups_of_standard_number(3, students_groups, students_ids)
      #Se mais da metade ja possui grupos OU se menos da metade ja possui grupos OU exatamente a metade possui grupo, pegar a média de alunos nesses grupos para dividir os novos grupos.
      elsif (total_quantity_students - students_without_group.length) >= (total_quantity_students / 2) ||
            (total_quantity_students - students_without_group.length) <= (total_quantity_students / 2) ||
             students_without_group.length == (total_quantity_students / 2)

        groups_assignments = GroupAssignment.where(academic_allocation_id: academic_allocation.id)

        average = calculate_average_students_per_group(academic_allocation.academic_tool.id, alloc_tag_id)

        students_remains_quantity = total_quantity_students % average.to_i
        students_groups = students_ids.in_groups_of(average.to_i, false)

        if students_remains_quantity == 0 #quantidade exata para formar um grupo

          if students_ids.length % average.to_i == 1 # caso sobrar um estudante sem grupo, inserir no último grupo
            students_groups[students_groups.length-2] << students_groups[students_groups.length-1][0]
            students_groups.pop
          end

          if average.to_i == 1

            quantity_students_per_assignment = GroupParticipant.select("group_assignment_id")
                                                .where(group_assignment_id: GroupAssignment.where(academic_allocation_id: academic_allocation.id).map{|ga| ga.id})
                                                .group(:group_assignment_id)
                                                .count

            group_participants_ids_to_remove = quantity_students_per_assignment.select{|key, value| value == 1 }

            unless group_participants_ids_to_remove.blank?
              ActiveRecord::Base.transaction do
                group_participants_ids_to_remove.each do |key, value|
                  ga = GroupAssignment.find(key)
                  students_ids << ga.group_participants[0].user_id
                  GroupParticipant.find(ga.group_participants[0].id).destroy
                  ga.destroy
                end
              end
            end

            students_groups = GroupAssignment.split_students_in_groups_of_standard_number(3, students_groups, students_ids)
          end

        else #&& students_ids.length > average.to_i
          remains = students_groups.pop

          if remains.length <= groups_assignments.length #quantidade de alunos sem grupos é igual ou é menor que a quantidade de grupos ja existentes (colocar um em cada grupo)
            groups_assignment_division = GroupAssignment.add_number_students_without_groups_is_equal_to_or_less_than_the_number_existing_groups(groups_assignment_division, groups_assignments, academic_allocation, remains)
          end

          if remains.length > groups_assignments.length #quantidade de alunos restantes sem grupo é maior que a quantidade de grupos ja existentes
            groups_assignment_division = GroupAssignment.remaining_students_without_group(groups_assignment_division, academic_allocation, remains, students_groups)
          end

        end
      end

      return groups_assignment_division, students_groups
    end

    def self.split_students_in_groups_of_standard_number(standard_number = 3, students_groups, students_ids)
      students_groups = students_ids.in_groups_of(standard_number, false) # divisão em grupos de 3

      if students_ids.length % standard_number == 1 # caso sobrar um estudante sem grupo, inserir no último grupo
        students_groups[students_groups.length-2] << students_groups[students_groups.length-1][0]
        students_groups.pop
      end

      students_groups
    end

    def self.add_number_students_without_groups_is_equal_to_or_less_than_the_number_existing_groups(groups_assignment_division, groups_assignments, academic_allocation, remains)
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
      return groups_assignment_division
    end

    def self.remaining_students_without_group(groups_assignment_division, academic_allocation, remains, students_groups)
      ActiveRecord::Base.transaction do
        name_group = "GRUPO #{students_groups.length + 1}"

        all_groups = GroupAssignment.where(academic_allocation_id: academic_allocation.id)
        unless all_groups.blank?
          all_group_names = all_groups.map{|g| g.group_name}
          if all_group_names.include? name_group
            number_group_array = []
            all_group_names.each{|gname| number_group_array << gname.split(" ")[1].to_i}
            name_group = "GRUPO #{number_group_array.max + 1}"
          end
        end

        group_assignment = GroupAssignment.create!(group_name: name_group, academic_allocation_id: academic_allocation.id)

        remains.each_with_index do |student_id, index|
          GroupParticipant.create!(group_assignment_id: group_assignment.id, user_id: student_id)
        end

        student_names_per_group = User.where(id: GroupParticipant.where(group_assignment_id: group_assignment.id).map{|gp| gp.user_id}).pluck(:name)
        struct = Struct::Group_Object.new(group_assignment.group_name, student_names_per_group)
        key_assignment = "#{group_assignment.assignment.name}_#{academic_allocation.id}"

        groups_assignment_division[key_assignment] ||= []
        groups_assignment_division[key_assignment] << struct
      end
      return groups_assignment_division
    end

    def self.calculate_average_students_per_group(academic_tool_id, allocation_tag_id)
      sql = "SELECT AVG(quantity)
            FROM(
                    SELECT DISTINCT gp.group_name, COUNT(gpa) as quantity
                    FROM group_assignments gp
                    INNER JOIN academic_allocations al ON al.id = gp.academic_allocation_id
                    INNER JOIN group_participants gpa ON gpa.group_assignment_id = gp.id
                    WHERE al.academic_tool_id = #{academic_tool_id}
                    AND al.allocation_tag_id IN (#{allocation_tag_id.join(",")})
                    GROUP BY gp.group_name
                )
              AS INNER_QUERY"

      ActiveRecord::Base.connection.exec_query(sql).rows.flatten[0]
    end

    def unique_group_name
      groups_with_same_name = GroupAssignment.where(academic_allocation_id: academic_allocation_id, group_name: group_name)
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
        html = "<p> #{I18n.t('group_assignments.split_group_jobs', assignment_key: assignment_key)} </p>"

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
