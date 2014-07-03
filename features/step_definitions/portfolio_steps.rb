def checar_dados_tabela(table_selector, table_data, options = {})
  options.reverse_merge!(:headers => true)

  page.should have_selector(table_selector)
  within(table_selector) do
    if !options[:headers]
      header_map = (0...table_data.rows.first.length).to_a
      row_count = table_data.raw.length
      table_rows = table_data.raw
    else
      header_map = []
      row_count = table_data.raw.length - 1
      within("thead tr:first") do
        columns = all("th").collect{ |column| column.text.downcase.strip }
        columns.size.should >= table_data.headers.size

        table_data.headers.each_with_index do |header, index|
          column = columns.index(header.downcase.strip)
          column.should_not be_nil
          header_map << column
        end
      end
      table_rows = table_data.raw[1...table_data.raw.length]
    end

    within("tbody") do
      puts "row_count"
      puts row_count
      puts "table_data"
      puts table_data.raw
      all("tr").size.should == row_count

      xpath_base = './/tr[%i]/td[%i]';
      table_rows.each_with_index do |row, index|
        row.each_with_index do |value, column|
          find(:xpath, xpath_base % [index + 1, header_map[column] + 1]).should have_content(value)
        end
      end
    end
  end
end

Então 'eu deverei ver os seguintes dados na tabela "$table_id":' do |table_id, table|
  checar_dados_tabela(table_id, table)
  # Exemplo caso a tabela não possua headers
  # checar_dados_tabela(table_id, table, :headers => false)
end