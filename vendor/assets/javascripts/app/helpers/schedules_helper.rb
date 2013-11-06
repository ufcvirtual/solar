module SchedulesHelper

  ##
  # 4 Formatos de exibicao:
  # 1 - O evento acontece apenas em um dia do mes do ano corrente
  # 2 - O evento acontece em um intervalo de dias mas dentro de um mesmo mes e do mesmo ano
  # 3 - O evento acontece entre meses diferentes e anos iguais
  # 4 - O evento acontece entre datas de anos diferentes
  ##
  def display_date_format(start_date, end_date = nil)

    # o evento ocorre somente uma vez
    if start_date == end_date || end_date.nil? # 1

      return <<TEXT
    <div class="agenda_left_day">
      #{start_date.day}
    </div>
    <div class="agenda_left_month_year">
      #{l(start_date, :format => :month_and_year)}
    </div>
TEXT

    end

    # verifica mesmo ano
    if start_date.year == end_date.year
      # verifica o mesmo mes
      if start_date.month == end_date.month # 2

        return <<TEXT
      <div class="agenda_left_interval">
        <span>#{start_date.day}</span>
        <span class="date_middle">-</span>
        <span>#{end_date.day}</span>
      </div>
      <div class="agenda_left_month_year">
        #{l(start_date, :format => :month_and_year)}
      </div>
TEXT

      else # 3 - meses diferentes no mesmo ano

        return <<TEXT
      <div class="agenda_left_interval">
        <span>#{l(start_date, :format => :day_and_month)}</span>
        <span class="date_middle">-</span>
        <span>#{l(end_date, :format => :day_and_month)}</span>
      </div>
      <div class="agenda_left_year">
        #{start_date.year}
      </div>
TEXT

      end

    else # 4 - anos diferentes

      return <<TEXT
    <div class="agenda_left_day_and_month">
      <span class="date_left">
        #{l(start_date, :format => :day_and_month)}
      </span>
      <span class="date_middle">-</span>
      <span class="date_right">
        #{l(end_date, :format => :day_and_month)}
      </span>
    </div>
    <div class="agenda_left_month_year">
      <span class="year_left">
        #{start_date.year}
      </span>
      <span class="year_right">
        #{end_date.year}
      </span>
    </div>
TEXT

    end

  end

end
