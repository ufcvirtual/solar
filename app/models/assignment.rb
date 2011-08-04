class Assignment < ActiveRecord::Base

  belongs_to :allocation_tag

  has_many :files_enunciations
  has_many :send_assignments

  # Recupera as atividades por turma
  def self.all_by_group_id(group_id)
    ActiveRecord::Base.connection.select_all <<SQL
    SELECT t1.id,
           t1.name,
           t1.start_date,
           t1.end_date
      FROM assignments     AS t1
      JOIN allocation_tags AS t2 ON t2.id = t1.allocation_tag_id
     WHERE t2.group_id = #{group_id}
     ORDER BY t1.start_date;
SQL
  end

end
