module EditionHelper

  ## Função que retorna o "caminho" do que está sendo consultado verificando o filtro
  # Ex:. Em módulos de aulas, foi selecionado um curso e todas as turmas. 
  # O caminho exibirá Período / UC / Turma (curso não é exibido pois foi selecionado previamente)
  ## Parâmetros:
  # => allocation_tag:   allocation_tag de um objeto em questão
  # => what_was_selecet: lista informado quais valores do filtro foram selecionados
  def allocation_tag_path(allocation_tag, what_was_selected)
  	group  			    = allocation_tag.group ? allocation_tag.group.code : nil
  	offer  			    = allocation_tag.offer ? allocation_tag.offer.semester : allocation_tag.group.offer.semester
  	curriculum_unit = group ? allocation_tag.group.curriculum_unit.name : allocation_tag.offer.curriculum_unit.name
  	course 			    = allocation_tag.course ? allocation_tag.course.name : (group ? allocation_tag.group.course.name : allocation_tag.offer.course.name)

  	allocation_tag_path = []
  	allocation_tag_path << course 		     unless what_was_selected[0] == "true"
    allocation_tag_path << offer           unless what_was_selected[1] == "true"
  	allocation_tag_path << curriculum_unit unless what_was_selected[2] == "true"
  	allocation_tag_path << group 		       unless what_was_selected[3] == "true"

  	return allocation_tag_path.compact.join(" / ")

   end

end
