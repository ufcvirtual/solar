class Profile < ActiveRecord::Base

  has_many :allocations
  has_many :users, :through => :allocations
  has_many :permissions_resources
  has_many :permissions_menus

  ##
  # recupera uma lista perfis que possuem quaisquer permissões requisitadas
  ##
  def self.authorized_profiles(resources)

    query = <<SQL
      SELECT DISTINCT p.*
      from
        profiles p
        inner join permissions_resources r on p.id = r.profile_id
      where
        r.profile_id in (#{resources.join(',')})
SQL
    return self.find_by_sql(query)
  end

  def has_type?(type)
    (self.types & type) == type
  end

  def self.student_from_class?(user_id, allocation_tag_id)
    students_of_class = Assignment.list_students_by_allocations(allocation_tag_id).map(&:id)
    return (students_of_class.include?(user_id))
  end

  ##
  # Verifica se o usuário, para a oferta e turma informadas, tem permissão de responsável ou de aluno
  ##
  def self.is_responsible_or_student?(user_id, offer_id, group_id)
    offer        = Offer.find(offer_id)
    unless offer.nil?
      access_offer = (offer.allocation_tag.is_user_class_responsible?(user_id) or offer.allocation_tag.is_student?(user_id))
      if group_id == 0 # nenhuma turma (verifica oferta)
        return access_offer
      elsif group_id == "all" # todas as turmas da oferta
        access_groups = offer.groups.where("status = #{true}").collect{|group| group.allocation_tag.is_user_class_responsible?(user_id) or group.allocation_tag.is_student?(user_id)}
        return (not(access_groups.include?(false)) or access_offer)
      else # alguma turma específica
        group = Group.find(group_id)
        return (group.allocation_tag.is_user_class_responsible?(user_id) or group.allocation_tag.is_student?(user_id))
      end
    end
  end

end
