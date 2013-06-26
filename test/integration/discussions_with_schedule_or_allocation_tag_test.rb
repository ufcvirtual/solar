require 'test_helper'
 
# Aqui estão os testes dos métodos do cotnroller discussions
# que, ao executá-los, são feitas alterações em schedules. 
# Há, também, o método index que precisa estar em uma allocation_tag
# para poder ser executado.

class DiscussionsWithScheduleOrAllocationTagTest < ActionDispatch::IntegrationTest
  fixtures :all
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 
  
  def setup
    @quimica_tab  = add_tab_path(id: 3, context:2, allocation_tag_id: 3)
    @edition_page = editions_path
    @items        = items_editions_path(:allocation_tags_ids => [allocation_tags(:al2)])
    @items2       = items_editions_path(:allocation_tags_ids => [allocation_tags(:al13)])
  end

  def login(user)
    login_as user, :scope => :user
  end

  ##
  # Listar fóruns por allocation_tag (index)
  ##
  
    test "listar foruns por allocation_tag" do
      login(users(:professor))
      get @quimica_tab
      get discussions_path
      assert_not_nil assigns(:discussions)
      assert_template :index
    end

    test "nao listar foruns por allocation_tag - sem permissao" do
      login(users(:tutor_presencial))
      get @quimica_tab
      get discussions_path
      assert_nil assigns(:discussions)
      assert_redirected_to(home_path)
      assert_equal flash[:alert], I18n.t(:no_permission)
    end

  ## 
  # Listar fóruns de uma oferta, de todas as turmas da oferta ou de uma turma (list)
  ##

  # Acessar pela página de edição

    test "listar foruns de acordo com dados de oferta e turma passados" do
      login users(:editor)
      get @edition_page
      get @items
      assert_not_nil assigns(:allocation_tags_ids)
      get( list_discussions_path, {:allocation_tags_ids => assigns(:allocation_tags_ids)} )
      assert_not_nil assigns(:discussions)
      assert_template :list
    end

    test "nao listar foruns de acordo com dados de oferta e turma passados - sem permissao" do
      login users(:professor)
      get @edition_page
      get @items
      get( list_discussions_path, {:allocation_tags_ids => assigns(:allocation_tags_ids)} )
      assert_nil assigns(:discussions)
      assert_response :error
    end

    test "criar novo forum" do
      login users(:editor)
      get @edition_page
      get @items
      get( new_discussion_path, {:allocation_tags_ids => assigns(:allocation_tags_ids).flatten} )
      assert_not_nil assigns(:discussion)
      assert_template :new

      assert_difference(["Discussion.count", "Schedule.count"], (assigns(:allocation_tags_ids).flatten.size)) do
        post("/discussions/", {:discussion => {:name => "discussion 1", :description => "discussion 1"}, :start_date => "30-01-2013", :end_date => "30-03-2013", :allocation_tags_ids => assigns(:allocation_tags_ids).flatten})
      end

      assert_response :success
    end

    test "nao criar novo forum - erro de validacao" do
      login(users(:editor))
      get @edition_page
      get @items
      get( new_discussion_path, {:allocation_tags_ids => assigns(:allocation_tags_ids)} )
      assert_not_nil assigns(:discussion)
      assert_template :new

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        post("/discussions/", {:discussion => {:description => "discussion 1"}, :start_date => "30-08-2012", :end_date => "30-11-2012", :allocation_tags_ids => assigns(:allocation_tags_ids)})
      end

      assert_response :success
      assert_template :new
    end

    test "nao criar novo forum - sem permissao" do
      login(users(:editor))
      get @edition_page
      get @items

      login(users(:professor))
      get( new_discussion_path, {:allocation_tags_ids => assigns(:allocation_tags_ids)} )
      assert_nil assigns(:discussion)

      assert_redirected_to(home_path)
      assert_equal I18n.t(:no_permission), flash[:alert]

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        post("/discussions/", {:discussion => {:name => "discussion 1", :description => "discussion 1"}, :start_date => "30-01-2013", :end_date => "30-03-2013", :allocation_tags_ids => assigns(:allocation_tags_ids).flatten})
      end

      assert_response :redirect
    end

     test "editar forum" do
      login(users(:editor))
      get @edition_page
      get @items
      get(edit_discussion_path(discussions(:forum_9), :allocation_tags_ids => assigns(:allocation_tags_ids)))
      assert_not_nil assigns(:discussion)
      assert_not_nil assigns(:allocation_tags_ids)
      assert_template :edit

      put( discussion_path(discussions(:forum_9), {:discussion => {:name => "discussion 2", :description => "discussion 1"}, :start_date => "30-01-2013", :end_date => "27-03-2013", :allocation_tags_ids => assigns(:allocation_tags_ids).flatten}) )
      assert_equal "27-03-2013", discussions(:forum_9).schedule.end_date.strftime("%d-%m-%Y")

      assert_response :success
     end

    test "nao editar forum - erro de validacao" do
      login(users(:editor))
      get @edition_page
      get @items
      get(edit_discussion_path(discussions(:forum_9), :allocation_tags_ids => assigns(:allocation_tags_ids)))
      assert_not_nil assigns(:discussion)
      assert_not_nil assigns(:allocation_tags_ids)
      assert_template :edit

      put( discussion_path(discussions(:forum_9), {:discussion => {:name => "", :description => "discussion 1"}, :start_date => "30-01-2013", :end_date => "31-03-2013", :allocation_tags_ids => assigns(:allocation_tags_ids).flatten}) )
      assert_not_equal "31-03-2013", discussions(:forum_9).schedule.end_date.strftime("%d-%m-%Y")

      assert_response :success
      assert_template :edit
    end

    test "nao editar forum - sem permissao" do
      login(users(:editor))
      get @edition_page
      get @items
      allocation_tags_ids = assigns(:allocation_tags_ids)

      login(users(:professor))
      get(edit_discussion_path(discussions(:forum_9), :allocation_tags_ids => assigns(:allocation_tags_ids)))
      assert_nil assigns(:allocation_tags_ids)

      put( discussion_path(discussions(:forum_9), {:discussion => {:name => "", :description => "discussion 1"}, :start_date => "30-01-2013", :end_date => "31-03-2013", :allocation_tags_ids => allocation_tags_ids}) )
      assert_not_equal discussions(:forum_9).schedule.end_date.strftime("%d-%m-%Y"), "31-03-2013"

      assert_response :redirect
    end

  ##
  # Excluir fórum (destroy)
  ##

    test "excluir forum" do
      login(users(:editor))
      get @edition_page
      get @items
      allocation_tags_ids = assigns(:allocation_tags_ids)
      get(list_discussions_path, {:allocation_tags_ids => allocation_tags_ids})
      assert_not_nil assigns(:discussions)
      assert_not_nil assigns(:allocation_tags_ids)
      
      assert_difference(["Discussion.count"], -1) do 
        assert_no_difference(["Schedule.count"]) do # o schedule não deve ser removido pois ele está associado à outros objetos
          delete(discussion_path(discussions(:forum_9), :allocation_tags_ids => allocation_tags_ids))
        end
      end

      assert_response :success

      get(list_discussions_path, {:allocation_tags_ids => allocation_tags_ids})
      assert_no_tag :tag => "td", :content => "\nForum 7\n" # verifica se o fórum foi excluido (não deve ser exibido na página)
    end

    test "nao excluir forum - forum ja possui postagens" do
      login(users(:editor))
      get @edition_page
      get @items2
      allocation_tags_ids = assigns(:allocation_tags_ids)
      get(list_discussions_path, {:allocation_tags_ids => allocation_tags_ids})
      assert_not_nil assigns(:discussions)
      assert_not_nil assigns(:allocation_tags_ids)

      assert_template :list

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        delete(discussion_path(discussions(:forum_1), :allocation_tags_ids => allocation_tags_ids))
      end

      assert_response :unprocessable_entity
    end

    test "nao excluir forum - sem permissao" do
      login(users(:editor))
      get @edition_page
      get @items
      allocation_tags_ids = assigns(:allocation_tags_ids)

      login(users(:professor))

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        delete(discussion_path(discussions(:forum_1), :allocation_tags_ids => allocation_tags_ids))
      end

      assert_response :unprocessable_entity
    end
    
end
