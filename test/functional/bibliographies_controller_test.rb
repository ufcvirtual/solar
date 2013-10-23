require 'test_helper'

class BibliographiesControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  fixtures :bibliographies

  def setup
    sign_in users(:editor)

    @params_book_without_author = {type_bibliography: Bibliography::TYPE_BOOK, title: "Titulo", address: "Fortaleza", publisher: "Editora", edition: 1, publication_year: "2013"}
    @params_book_with_author = @params_book_without_author.merge({authors_attributes: {"0" => {name: "Autor"}}})
    @quimica = allocation_tags(:al3).id
  end

  test "rotas" do
    ## apenas algumas rotas
    assert_routing({method: :get, path: "/bibliographies/new_book"}         , {controller: "bibliographies", action: "new", type_bibliography: Bibliography::TYPE_BOOK})
    assert_routing({method: :get, path: "/bibliographies/new_periodical"}   , {controller: "bibliographies", action: "new", type_bibliography: Bibliography::TYPE_PERIODICAL})
    assert_routing({method: :get, path: "/bibliographies/new_article"}      , {controller: "bibliographies", action: "new", type_bibliography: Bibliography::TYPE_ARTICLE})
    assert_routing({method: :get, path: "/bibliographies/new_electronic_doc"}, {controller: "bibliographies", action: "new", type_bibliography: Bibliography::TYPE_ELECTRONIC_DOC})
    assert_routing({method: :get, path: "/bibliographies/new_free"}         , {controller: "bibliographies", action: "new", type_bibliography: Bibliography::TYPE_FREE})
  end

  test "cadastrar livro" do
    assert_difference(["AcademicAllocation.count", "Bibliography.count", "Author.count"], 1) do
      post :create, {allocation_tags_ids: "#{@quimica}",
        bibliography: @params_book_with_author
      }
    end
  end

  test "nao cadastrar livro sem autor" do
    assert_no_difference(["AcademicAllocation.count", "Bibliography.count", "Author.count"]) do
      post :create, {allocation_tags_ids: "#{@quimica}",
        bibliography: @params_book_without_author
      }
    end

    assert_template :new
  end

  test "deletar livros e autores" do
    assert_difference(["AcademicAllocation.count", "Bibliography.count", "Author.count"], 1) do
      post :create, {allocation_tags_ids: "#{@quimica}",
        bibliography: @params_book_with_author
      }
    end

    assert_difference(["AcademicAllocation.count", "Bibliography.count", "Author.count"], -1) do
      delete :destroy, {id: Bibliography.last.id, allocation_tags_ids: [@quimica]}
    end
  end

  test "deletar apenas um autor de um livro com dois autores" do
    assert_difference(["Author.count"], -1) do
      assert_no_difference(["AcademicAllocation.count", "Bibliography.count"]) do
        put :update, {id: bibliographies(:livro1).id, allocation_tags_ids: "#{@quimica}", bibliography: bibliographies(:livro1).as_json.merge({authors_attributes: {"0" => {id: authors(:author1).id, _destroy: "true"}}})}
      end
    end
  end

  test "sem permissao - nao deletar livro" do
    sign_in users(:aluno1)

    assert_no_difference(["AcademicAllocation.count", "Bibliography.count", "Author.count"]) do
      delete :destroy, {id: bibliographies(:livro1).id, allocation_tags_ids: [@quimica]}
    end

    assert_equal flash[:alert], I18n.t(:no_permission)
  end

  test "edicao - listar bibliographies" do
    get :list, {allocation_tags_ids: [@quimica]}
    assert_response :success
  end

end
