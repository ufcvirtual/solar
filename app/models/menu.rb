class Menu < ActiveRecord::Base

  # auto-relacionamento
  has_many :children, :class_name => "Menu", :foreign_key => "father_id"
  belongs_to :father, :class_name => "Menu"

  # outros relacionamentos
  has_many :permissions_menus
  has_many :resources

  belongs_to :context

  def self.find_by_controller_and_action_name(controller, action)
    
  end

  # Lista com os menus do perfil do usuario dependendo do contexto
  def self.list_by_profile_id_and_context(profile_id, context = 'geral')
    # consulta para recuperar os dados do menu
    query = "
      WITH cte_menus AS (
       SELECT DISTINCT
              t1.id    AS father_id,
              t1.order AS father_order,
              t1.name  AS father,
              t2.id    AS child_id,
              t2.order AS child_order,
              t2.name  AS child,
              t2.resource_id
         FROM menus             AS t1                           -- menu pai
         JOIN menus             AS t2 ON (t2.father_id = t1.id) -- menu filho
         JOIN permissions_menus AS t3 ON (t3.menu_id = t2.id) -- verifica permissoes aos menus filhos
        WHERE t2.status = TRUE AND t3.profile_id IN (#{profile_id}) -- permissoes para os menus filhos
      ), -- menus filhos com permissoes associadas
      --
      cte_all_fathers AS (
          SELECT DISTINCT
                 t1.id    AS father_id,
                 t1.order AS father_order,
                 t1.name  AS father,
                 t3.child_order,
                 t3.child_id,
                 t3.child,
                 COALESCE(t3.resource_id, t1.resource_id) AS resource_id, -- resource do filho, senao do pai
                 COALESCE(t4.name, 'geral') AS context,
                 t1.link
            FROM menus             AS t1 -- recuperando todos os menus-pai
            JOIN permissions_menus AS t2 ON (t2.menu_id = t1.id AND t1.father_id IS NULL) -- verifica permissoes aos menus pais
       LEFT JOIN cte_menus         AS t3 ON (t3.father_id = t1.id)
       LEFT JOIN contexts          AS t4 ON (t4.id = t1.context_id)
           WHERE t1.status = TRUE AND t2.profile_id IN (#{profile_id}) -- permissoes para os menus pais
      )
      SELECT t1.father_id,
             t1.father,
             t1.father_order,
             t1.child,
             t1.child_order,
             t1.context,
             t1.resource_id,
             t2.controller,
             t2.action,
             t1.link
        FROM cte_all_fathers  AS t1
   LEFT JOIN resources        AS t2 ON (t2.id = t1.resource_id)
       WHERE (t1.context = 'geral' OR t1.context = '#{context}')
         AND ((t1.resource_id IS NOT NULL AND t2.status = TRUE) OR (t1.resource_id IS NULL AND t1.child IS NULL)) -- verifica se o registro eh um pai ou nao
       ORDER BY t1.father_order, t1.child_order;"

    menus = ActiveRecord::Base.connection.select_all query

    return (menus.first.nil?) ? [] : menus

  end

end
