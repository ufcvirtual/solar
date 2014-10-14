module Helpers::V1::EventsH

  def get_event_type_and_description(type)
    case type.to_i
      when 1; {type: 2, title: "Encontro Presencial"} # encontro presencial
      when 2; {type: 1, title: "Prova Presencial: AP - 1ª chamada"} # prova presencial - AP - 1ª chamada
      when 3; {type: 1, title: "Prova Presencial: AP - 2ª chamada"} # prova presencial - AP - 2ª chamada
      when 4; {type: 1, title: "Prova Presencial: AF - 1ª chamada"} # prova presencial - AF - 1ª chamada
      when 5; {type: 1, title: "Prova Presencial: AF - 2ª chamada"} # prova presencial - AF - 2ª chamada
      when 6; {type: 5, title: "Aula por Web Conferência"} # aula por webconferência
    end
  end

end