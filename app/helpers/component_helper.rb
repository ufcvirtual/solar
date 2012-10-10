=begin

  = Campos do filtro
    - Curso/Graduacao
    - Periodo/Oferta
    - Unidade Curricular
    - Turma

  = Listar apenas informações em que o usuário tem alguma ligação com permissão de edição
    - verificar em qual ponto da hierarquia o usuario tem permissao para visualizar
      - listar todas as informacoes abaixo desse ponto
        - uc, oferta, turma

  =====
  -- o usuario é obrigado a selecionar a allocation_tag onde tem associação (e as allocation_tags acima na hierarquia)
    -- se é associado a uma unidade curricular
      -- é obrigado a escolhar uma graduacao em um periodo, e o periodo
        -- esses campos nao podem ficar vazios ou com opcao --TODOSO--


  -- obrigar usuario a escolher uma opcao quando nem tem alocacao na hierarquia pra cima

=end

module ComponentHelper

  def filter
    raw %{
      <form>
        <label for="course">Curso</label>
        <label for="period">Periodo</label>
        <label for="curriculum_unit">Unidade Curricular</label>
        <label for="group">Turma</label>
      </form>
    }
  end

end
