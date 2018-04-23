class BibliographyAddFields < ActiveRecord::Migration[5.0]

  # como a tabela muda, é necessário esse código junto com o código de reset
  class Bibliography < ActiveRecord::Base
  end

  def up
    bibliographies = Bibliography.all

    drop_table :bibliographies

    create_table :bibliographies do |t|
      t.integer :type_bibliography, null: false
      t.text :title, null: false
      t.text :subtitle
      t.string :address
      t.string :publisher
      t.integer :count_pages
      t.string :pages, limit: 50
      t.integer :volume
      t.integer :edition
      t.integer :publication_year
      t.string :periodicity
      t.string :issn, limit: 9 # 9999-999x
      t.string :isbn, limit: 17 #  978-3-16-148410-0
      t.integer :periodicity_year_start
      t.integer :periodicity_year_end
      t.text :article_periodicity_title
      t.integer :fascicle
      t.string :publication_month, limit: 50
      t.text :additional_information
      t.text :url
      t.date :accessed_in

      t.timestamps
    end

    Bibliography.reset_column_information

    bibliographies.each do |bibliography|
      title = []
      title << bibliography.author                    if not bibliography.author.nil?
      title << bibliography.title                     if not bibliography.title.nil?
      title << bibliography.edition                   if not bibliography.edition.nil?
      title << bibliography.locale                    if not bibliography.locale.nil?
      title << bibliography.publisher                 if not bibliography.publisher.nil?
      title << bibliography.year                      if not bibliography.year.nil?
      title << bibliography.additional_text           if not bibliography.additional_text.nil?
      title << "ISBN/ISSN: #{bibliography.isbn_issn}" if not bibliography.isbn_issn.nil?
      title << "URL: #{bibliography.url}"             if not bibliography.url.nil?
      title = title.join(". ")

      bib = Bibliography.create type_bibliography: ::Bibliography::TYPE_FREE, title: title # mudar pela constante
      AcademicAllocation.create(allocation_tag_id: bibliography.allocation_tag_id, academic_tool_id: bib.id, academic_tool_type: 'Bibliography')
    end
  end

  def down
    raise "without rollback"
  end
end
