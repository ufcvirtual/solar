class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user

    unless user.id.nil?
      query = "
          SELECT t1.id AS profile_id,
                 t3.controller,
                 t3.action,
                 t2.per_id
            FROM profiles                   AS t1
            JOIN permissions_resources      AS t2 ON t2.profile_id = t1.id
            JOIN resources                  AS t3 ON t3.id = t2.resource_id
            JOIN allocations                AS t4 ON t4.profile_id = t1.id
            LEFT JOIN allocation_tags       AS t5 ON t5.id = t4.allocation_tag_id
           WHERE t4.user_id = #{user.id}
             AND t2.status = TRUE
             AND t4.status = 1
           GROUP BY t1.id, t3.controller, t3.action, t2.per_id
           ORDER BY 1, 2;"

      permissions = ActiveRecord::Base.connection.select_all query
      permissions.each do |permission|
        can permission['action'].to_sym, model_name(permission['controller']) do |object|
          permission['per_id'] == 'f' or (user_have_permission_to?(user, object, permission['profile_id']) or (object.class.to_s == 'User' and object.id == user.id))
        end
      end
    else
      can [:create, :pwd_recovery], User # permissoes para usuarios nao logados
    end
  end

  private

  def model_name(word)
    word.capitalize.singularize.camelize.constantize
  end

  def user_have_permission_to?(user, object, profile_id)
    return true if (object.respond_to?(:user_id) and object.user_id == user.id)

    ## usuario está associado às uma das associacoes por belongs_to
    object.class.reflect_on_all_associations(:belongs_to).each do |class_related|
      return true if (object.respond_to?(class_related.name) and object.send(class_related.name).respond_to?(:user_id) and (object.send(class_related.name).user_id == user.id))
    end

    ## associacoes por allocation_tag
    if object.respond_to?(:allocation_tag)
      user_allocations_tag = user.allocations.where(profile_id: profile_id.to_i, status: Allocation_Activated.to_i).map(&:allocation_tag)
      allocation_tag       = object.send(:allocation_tag)

      ## se o usuario já está ligado diretamente à allocation_tag ou por meio da hierarquia
      return true if (user_allocations_tag.include?(allocation_tag) or (not (user_allocations_tag.map(&:id) & up_related(allocation_tag)).empty?))
    end

    ## ligada a allocation diretamente
    return true if (object.respond_to?(:allocations) and (not object.send(:allocations).where(user_id: user.id, profile_id: profile_id.to_i, status: Allocation_Activated.to_i).empty?))
    return false
  end

  def up_related(allocation_tag)
    option = allocation_tag.attributes.delete_if {|key, value| key == 'id' or value.nil?}.map {|k,v| k}.first

    return case option
      when 'group_id'
        [allocation_tag.group.offer.allocation_tag.id, allocation_tag.group.curriculum_unit.allocation_tag.id, allocation_tag.group.course.allocation_tag.id]
      when 'offer_id'
        [allocation_tag.offer.curriculum_unit.allocation_tag.id, allocation_tag.offer.course.allocation_tag.id]
      when 'curriculum_unit_id', 'course_id'
        []
    end
  end

end
