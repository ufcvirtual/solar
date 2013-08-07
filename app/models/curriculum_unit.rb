class CurriculumUnit < ActiveRecord::Base

  include Taggable

  belongs_to :curriculum_unit_type

  has_many :offers
  has_many :groups, :through => :offers, :uniq => true
  has_many :courses, :through => :offers, :uniq => true

  validates :code, :uniqueness => true, :length => { :maximum   => 10 }, :allow_blank => true
  validates :name, :presence => true, :length => { :maximum   => 120 }
  validates :curriculum_unit_type, :presence => true  
  validates :resume, :presence => true
  validates :syllabus, :presence => true
  validates :objectives, :presence => true, :length => { :maximum   => 255 }
  validates :passing_grade, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10, :allow_blank => true}

  default_scope :order => 'name ASC'

  after_destroy :delete_course, if: "curriculum_unit_type_id == 3"

  def delete_course
    Course.find_by_name(name).try(:destroy)
  end

  ##  
  # Participantes que não são TAL TIPO DE PERFIL
  ##
  def self.class_participants_by_allocations_tags_and_is_not_profile_type(allocation_tags, profile_flag)
    class_participants_by_allocations(allocation_tags, profile_flag, false)
  end

  ##
  # Participantes que sao determinado tipo de perfil
  ##
  def self.class_participants_by_allocations_tags_and_is_profile_type(allocation_tags, profile_flag)
    class_participants_by_allocations(allocation_tags, profile_flag)
  end

  def self.class_participants_by_allocations(allocation_tags, profile_flag, have_profile = true )
    negative = have_profile ? '' : 'NOT'

    query = <<SQL
      SELECT t3.id,
             initcap(t3.name) AS name,
             t3.photo_file_name,
             t3.photo_updated_at,
             t3.email,
             replace(translate(array_agg(t4.name)::text,'{""}',''),',',', ') AS profile_name,
             translate(array_agg(t4.id)::text,'{}','') AS profile_id
        FROM allocations     AS t1
        JOIN allocation_tags AS t2 ON t1.allocation_tag_id = t2.id
        JOIN users           AS t3 ON t1.user_id = t3.id
        JOIN profiles        AS t4 ON t4.id = t1.profile_id
       WHERE t2.id IN (#{allocation_tags})
         AND #{negative} cast(t4.types & '#{profile_flag.to_s(2)}' as boolean)
         AND t1.status = #{Allocation_Activated}
       GROUP BY t3.id, t3.name, t3.photo_file_name, t3.email, t3.photo_updated_at
       ORDER BY t3.name, profile_name
SQL

    User.find_by_sql query
  end

  ##
  # Retorna as unidades curriculares que o usuário atual está relacionado
  ##
  def self.find_default_by_user_id(user_id, as_object = false)
    user_activated_allocations = User.find(user_id).allocations.where(status: Allocation_Activated)
    allocation_tags_ids        = user_activated_allocations.flatten.map(&:allocation_tag_id).uniq

    curriculum_units, offers, groups = [], [], []
    allocation_tags_ids.each_with_index do |at, idx|
      curriculum_units[idx] =  CurriculumUnit.joins(:allocation_tag).where("allocation_tags.id = #{at.to_i}").flatten 
      offers[idx] = Offer.joins(:allocation_tag).where("allocation_tags.id = #{at.to_i}") 
      curriculum_units[idx] = offers[idx].collect{|offer| offer.curriculum_unit} if curriculum_units[idx].empty?
      groups[idx] = Group.joins(:allocation_tag).where("allocation_tags.id = #{at.to_i}") 
      curriculum_units[idx] = groups[idx].collect{|group| group.curriculum_unit} if curriculum_units[idx].empty?
      curriculum_units[idx] = Course.joins(:allocation_tag).where("allocation_tags.id = #{at.to_i}").collect{|course| course.curriculum_units} if curriculum_units[idx].empty?
      offers[idx] = offers[idx].empty? ? "" : offers[idx][0].id
      groups[idx] = groups[idx].empty? ? "" : groups[idx][0].id
    end

    return {"curriculum_units" => curriculum_units.uniq, "allocation_tags_ids" => allocation_tags_ids}
  end

  ##
  # Todas as UCs do usuario, atraves das allocations
  ##
  def self.all_by_user(user)
    al              = user.allocations.where(status: Allocation_Activated)
    my_direct_uc    = al.map(&:curriculum_unit)
    ucs_by_offers   = al.map(&:offer).compact.map(&:curriculum_unit).uniq
    ucs_by_courses  = al.map(&:course).compact.map(&:curriculum_units).uniq
    ucs_by_groups   = al.map(&:group).compact.map(&:curriculum_unit).uniq

    return [my_direct_uc + ucs_by_offers + ucs_by_courses + ucs_by_groups].flatten.compact.uniq.sort
  end

  def has_any_lower_association?
    self.offers.count > 0
  end

  def lower_associated_objects
    offers
  end

  def code_name
    code.blank? ? name : [code, name].join(' - ')
  end

end
