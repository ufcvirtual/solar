=begin

  = Campos do filtro
    - Curso/Graduacao
    - Unidade Curricular
    - Oferta
    - Turma

  = Listar apenas informações em que o usuário tem alguma ligação com permissão de edição
    - verificar em qual ponto da hierarquia o usuario tem permissao para visualizar
      - listar todas as informacoes abaixo desse ponto
        - uc, oferta, turma

  = Exibir como sendo obrigatório seguir a hierarquia
    - a seleção de baixo só poderá ser feita existir seleção em cima
  = Exibir com a possibilidade de filtrar por qualquer campo da hierarquia


===============
  - gr1
    - uc1
      - of11
      - of12
      - of13

  - gr2
    - uc2
      - of21
      - of22

  - professor editor de of11 e of12
    -- nao lista of3
  - professor editor de uc2
    -- lista todas as ofertas
  - professor editor de uc2 e of21
    -- lista todas as ofertas

=end

module ComponentHelper

  def filter(user = nil)
    user ||= current_user

    al      = user.allocations.joins(:profile).where("(profiles.types & #{Profile_Type_Student})::boolean IS FALSE AND allocations.allocation_tag_id IS NOT NULL").compact.uniq ## allocations onde o usuario tem permissao de edicao
    ucs     = al.map(&:curriculum_unit).flatten.compact.uniq
    groups  = al.map(&:groups).flatten.uniq
    offers  = [al.map(&:offer) + al.map(&:curriculum_unit).compact.map(&:offers)].flatten.compact.uniq
    courses = [al.map(&:course) + [groups.first.offer.course]].flatten.compact.uniq

    ## verificar hierarquia mais alta para filtro

    form = form_tag("", :method => "get") do
      select_tag(:course, options_for_select(offers.map {|o| [o.semester, o.id] }))
    end

    raw %{
      course: #{courses.map(&:name)} <br />
      ucs   : #{ucs.map(&:name)} <br />
      offers: #{offers.map(&:semester)} <br />
      groups: #{groups.map(&:code)} <br />

      #{form}
    }
  end

end
