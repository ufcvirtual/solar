class CurriculumUnit < ActiveRecord::Base

  belongs_to :curriculum_unit_type
  has_one :allocation_tag, :dependent => :destroy
  has_many :offers
  has_many :logs
  
  validates :name, :presence => true
  validates :curriculum_unit_type, :presence => true  
  validates :resume, :presence => true
  validates :syllabus, :presence => true
  validates :objectives, :presence => true

  after_create :allocation_tag_association
  
  def self.find_user_groups_by_curriculum_unit(curriculum_unit_id, user_id)
    query = "
           SELECT
            DISTINCT *
            FROM (
            ( --(cns 1 - usuarios vinculados direto a unidade curricular)
              SELECT
                gr.id, gr.code, of.semester
              FROM
                allocations al
                INNER JOIN allocation_tags tg ON tg.id = al.allocation_tag_id
                INNER JOIN curriculum_units cr ON cr.id = tg.curriculum_unit_id
                INNER JOIN offers of ON of.curriculum_unit_id = cr.id
                INNER JOIN groups gr ON gr.offer_id = of.id
              WHERE
                user_id = #{user_id} AND al.status = #{Allocation_Activated} AND cr.id = #{curriculum_unit_id}
            )
            union
            ( --(cns 2 - usuarios vinculados a oferta)
              SELECT
                gr.id, gr.code, of.semester
              FROM
                allocations al
                INNER JOIN allocation_tags tg ON tg.id = al.allocation_tag_id
                INNER JOIN offers of ON of.id = tg.offer_id
                INNER JOIN groups gr ON gr.offer_id = of.id
                INNER JOIN curriculum_units cr ON cr.id = of.curriculum_unit_id
              WHERE
                user_id = #{user_id} AND al.status = #{Allocation_Activated} AND cr.id = #{curriculum_unit_id}
            )
            union
            ( --(cns 3 - usuarios vinculados a turma)
              SELECT
                gr.id, gr.code, of.semester
              FROM
                allocations al
                INNER JOIN allocation_tags tg ON tg.id = al.allocation_tag_id
                INNER JOIN groups gr ON gr.id = tg.group_id
                INNER JOIN offers of ON of.id = gr.offer_id
                INNER JOIN curriculum_units cr ON cr.id = of.curriculum_unit_id
              WHERE
                user_id = #{user_id} AND al.status = #{Allocation_Activated} AND cr.id = #{curriculum_unit_id}
            )
            union
            ( --(cns 4 - usuarios vinculados a graduacao)
              SELECT
                gr.id, gr.code, of.semester
              FROM
                allocations al
                INNER JOIN allocation_tags tg ON tg.id = al.allocation_tag_id
                INNER JOIN courses cs ON cs.id = tg.course_id
                INNER JOIN offers of ON of.course_id = cs.id
                INNER JOIN groups gr ON gr.offer_id = of.id
                INNER JOIN curriculum_units cr ON cr.id = of.curriculum_unit_id
              WHERE
                user_id = #{user_id} AND al.status = #{Allocation_Activated} AND cr.id = #{curriculum_unit_id}
            )
          ) AS ucs_do_usuario
          ORDER BY semester DESC, code"

    groups1 = Group.find_by_sql(query)
    return (groups1.nil?) ? [] : groups1
  end

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
    WITH cte_all_by_user AS (
        SELECT DISTINCT t2.id AS allocation_tag_id, t2.group_id, t2.offer_id, t2.curriculum_unit_id, t2.course_id
          FROM allocations      AS t1
          JOIN allocation_tags  AS t2 ON t2.id = t1.allocation_tag_id
         WHERE t1.status = #{Allocation_Activated}
           AND t1.user_id = #{user_id}
    )
    --
    SELECT DISTINCT ON (name, curriculum_unit_id) curriculum_unit_id AS id, name, allocation_tag_id, offer_id, group_id, semester
      FROM (
        SELECT id AS curriculum_unit_id, name, allocation_tag_id, offer_id, group_id, semester FROM (
            (
                SELECT t2.*, NULL AS offer_id, NULL::integer AS group_id, NULL::varchar AS semester, t1.allocation_tag_id --usuarios vinculados direto a unidade curricular
                  FROM cte_all_by_user  AS t1
                  JOIN curriculum_units AS t2 ON t2.id = t1.curriculum_unit_id
            )
              UNION
            (
                SELECT t3.*, t2.id AS offer_id, NULL::integer AS group_id, semester, t1.allocation_tag_id --usuarios vinculados a oferta
                  FROM cte_all_by_user  AS t1
                  JOIN offers           AS t2 ON t2.id = t1.offer_id
                  JOIN curriculum_units AS t3 ON t3.id = t2.curriculum_unit_id
            )
              UNION
            (
                SELECT t4.*, t3.id AS offer_id, t2.id AS group_id, semester, t1.allocation_tag_id -- usuarios vinculados a turma
                  FROM cte_all_by_user  AS t1
                  JOIN groups           AS t2 ON t2.id = t1.group_id
                  JOIN offers           AS t3 ON t3.id = t2.offer_id
                  JOIN curriculum_units AS t4 ON t4.id = t3.curriculum_unit_id
            )
              UNION
            (
                select t4.*, t3.id AS offer_id, NULL::integer AS group_id, semester, t1.allocation_tag_id --usuarios vinculados a graduacao
                  FROM cte_all_by_user  AS t1
                  JOIN courses          AS t2 ON t2.id = t1.course_id
                  JOIN offers           AS t3 ON t3.course_id = t2.id
                  JOIN curriculum_units AS t4 ON t4.id = t3.curriculum_unit_id
            )
        ) AS curriculum_units ORDER BY name, semester DESC, id
    ) AS curriculum_units_with_allocations;
SQL

    as_object ? CurriculumUnit.find_by_sql(query) : ActiveRecord::Base.connection.select_all(query)
  end
  
  private 
  def allocation_tag_association
    AllocationTag.create(:curriculum_unit => self)
  end

end
