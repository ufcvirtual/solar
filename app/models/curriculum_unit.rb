class CurriculumUnit < ActiveRecord::Base
  

  belongs_to :curriculum_unit_type
  has_many :offers
  has_many :groups, :through => :offers, :uniq => true

  validates :code, :uniqueness => true, :length => { :maximum   => 10 }
  validates :name, :presence => true, :length => { :maximum   => 120 }
  validates :curriculum_unit_type, :presence => true  
  validates :resume, :presence => true
  validates :syllabus, :presence => true
  validates :objectives, :presence => true, :length => { :maximum   => 255 }

  ##  
  # participantes que nao sao TAL TIPO DE PERFIL
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

  def self.find_default_by_user_id(user_id, as_object = false)
    query = <<SQL
    WITH cte_user_activated_allocation_tags AS (
        SELECT DISTINCT t2.id AS allocation_tag_id, t2.group_id, t2.offer_id, t2.curriculum_unit_id, t2.course_id
          FROM allocations      AS t1
          JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
         WHERE t1.status = #{Allocation_Activated}
           AND t1.user_id = #{user_id}
    )
    --
    SELECT DISTINCT ON (name, curriculum_unit_id) curriculum_unit_id AS id, code, name, curriculum_unit_type_id, allocation_tag_id
      FROM (
        SELECT id AS curriculum_unit_id, code, name, curriculum_unit_type_id, allocation_tag_id, offer_id, group_id, semester FROM (
            (
                SELECT t2.*, NULL AS offer_id, NULL::integer AS group_id, NULL::varchar AS semester, t1.allocation_tag_id --usuarios vinculados direto a unidade curricular
                  FROM cte_user_activated_allocation_tags  AS t1
                  JOIN curriculum_units AS t2 ON t2.id = t1.curriculum_unit_id
            )
              UNION
            (
                SELECT t3.*, t2.id AS offer_id, NULL::integer AS group_id, semester, t1.allocation_tag_id --usuarios vinculados a oferta
                  FROM cte_user_activated_allocation_tags  AS t1
                  JOIN offers           AS t2 ON t2.id = t1.offer_id
                  JOIN curriculum_units AS t3 ON t3.id = t2.curriculum_unit_id
            )
              UNION
            (
                SELECT t4.*, t3.id AS offer_id, t2.id AS group_id, semester, t1.allocation_tag_id -- usuarios vinculados a turma
                  FROM cte_user_activated_allocation_tags  AS t1
                  JOIN groups           AS t2 ON t2.id = t1.group_id
                  JOIN offers           AS t3 ON t3.id = t2.offer_id
                  JOIN curriculum_units AS t4 ON t4.id = t3.curriculum_unit_id
            )
              UNION
            (
                select t4.*, t3.id AS offer_id, NULL::integer AS group_id, semester, t1.allocation_tag_id --usuarios vinculados a graduacao
                  FROM cte_user_activated_allocation_tags  AS t1
                  JOIN courses          AS t2 ON t2.id = t1.course_id
                  JOIN offers           AS t3 ON t3.course_id = t2.id
                  JOIN curriculum_units AS t4 ON t4.id = t3.curriculum_unit_id
            )
        ) AS curriculum_units ORDER BY name, semester DESC, id
    ) AS curriculum_units_with_allocations;
SQL

    as_object ? CurriculumUnit.includes(:curriculum_unit_type).find_by_sql(query) : ActiveRecord::Base.connection.select_all(query)
  end

  def has_any_lower_association?
      self.offers.count > 0
  end

  def lower_associated_objects
    offers
  end
  
  private 
  include Taggable

end
