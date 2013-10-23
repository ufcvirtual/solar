require 'test_helper'

class BibliographyTest < ActiveSupport::TestCase

  fixtures :bibliographies

  test "criar livro" do
    params = {type_bibliography: Bibliography::TYPE_BOOK, address: "Fortaleza", publisher: "Editora", edition: 1, publication_year: "2013", authors_attributes: {"0" => {name: "Autor"}}}

    bib = Bibliography.new params
    assert bib.invalid?

    bib.title = "Titulo"
    assert bib.valid?

    assert bib.save
  end

  test "criar livro com mais de um autor" do
    params = {type_bibliography: Bibliography::TYPE_BOOK, title: "Title", address: "Fortaleza", publisher: "Editora", edition: 1, publication_year: "2013", authors_attributes: {"0" => {name: "Autor 1"}, "1" => {name: "Autor 2"}}}

    bib = Bibliography.new params
    assert bib.valid?
    assert bib.save

    assert_equal bib.authors.count, 2
  end

  test "criar artigo" do
    params = {type_bibliography: Bibliography::TYPE_ARTICLE, address: "Fortaleza", pages: 12, volume: 1, publication_year: "2013", publication_month: "Janeiro", authors_attributes: {"0" => {name: "Autor"}}}

    bib = Bibliography.new params
    assert bib.invalid?

    bib.title = "Titulo"
    assert bib.valid?

    assert bib.save
  end

  test "criar periodico" do
    params = {type_bibliography: Bibliography::TYPE_PERIODICAL, address: "Fortaleza", publisher: "Editora", periodicity_year_start: "2011"}

    bib = Bibliography.new params
    assert bib.invalid?

    bib.title = "Titulo"
    assert bib.valid?

    assert bib.save
  end

  test "criar doc eletronico" do
    params = {type_bibliography: Bibliography::TYPE_ELECTRONIC_DOC, url: "www.google.com", accessed_in: Date.today, authors_attributes: {"0" => {name: "Autor"}}}

    bib = Bibliography.new params
    assert bib.invalid?

    bib.title = "Titulo"
    assert bib.valid?

    assert bib.save
  end

  test "criar livre" do
    bib = Bibliography.new type_bibliography: Bibliography::TYPE_FREE
    assert bib.invalid?

    bib.title = "Titulo"
    assert bib.valid?

    assert bib.save
  end

end
