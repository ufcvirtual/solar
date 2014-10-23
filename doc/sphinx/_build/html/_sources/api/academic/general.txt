Métodos gerais a todos os itens acadêmicos
==========================================

1. Remoção
----------

Objetivo
~~~~~~~~
  Remover curso ou disciplina ou oferta ou turma (definido em :type)

Chamada
~~~~~~~
  DELETE **:type**/**:id**

Parâmetros
~~~~~~~~~~
  *Nenhum parâmetro se faz necessário.*

Observações
~~~~~~~~~~~
  1. **:type** deve ser: "curriculum_unit", "course", "offer" ou "group";
  2. **:id** faz referência ao id do type (id do curso, da oferta, da turma ou da disciplina).
  
Resposta
~~~~~~~~
  *Status: 200 OK*
  
  *{ ok: :ok }*


