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
    @quimica_tab = add_tab_path(id: 3, context:2, allocation_tag_id: 3)
    @edition_page = editions_path
  end

  def login(user)
    login_as user, :scope => :user
  end

=begin
  
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
      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)
    end


  ## 
  # Listar fóruns de uma oferta, de todas as turmas da oferta ou de uma turma (list)
  ##

  #acessar pela página de edição

    test "listar foruns de acordo com dados de oferta e turma passados" do
      login users(:editor)
      get @edition_page
      assert_not_nil assigns(:allocation_tags_ids)
      get( list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)} )
      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:discussions)
      assert_template :list
    end

    test "nao listar foruns de acordo com dados de oferta e turma passados - sem permissao" do
      login users(:professor)
      get @edition_page
      get( list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)} )
      assert_nil assigns(:offer_id)
      assert_nil assigns(:group_id)
      assert_nil assigns(:discussions)
      
      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)
    end

  ##
  # Novo fórum (new/create)
  ##
  
    test "criar novo forum" do
      login users(:editor)
      get @edition_page
      get(new_discussion_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)}.to_param)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:discussion)
      assert_template :new

      assert_difference(["Discussion.count", "Schedule.count"], +(offers(:of3).groups.size)) do
        post("/discussions/", {:discussion => {:name => "discussion 1", :description => "discussion 1"}, :start_date => "30-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids).join(" ")})
      end

      assert_template :list
    end

    test "nao criar novo forum - erro de validacao" do
      login(users(:editor))
      get @edition_page
      get(new_discussion_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)}.to_param)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:discussion)
      assert_template :new

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        post("/discussions/", {:discussion => {:description => "discussion 1"}, :start_date => "30-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids).join(" ")})
      end

      assert_template :new
    end

    test "nao criar novo forum - sem permissao" do
      login(users(:editor))
      get @edition_page
      allocation_tags_ids = assigns(:allocation_tags_ids)

      login(users(:professor))
      get(new_discussion_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => allocation_tags_ids}.to_param)
      assert_nil assigns(:group_id)
      assert_nil assigns(:offer_id)
      assert_nil assigns(:discussion)
      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        post("/discussions/", {:discussion => {:name => "discussion 1", :description => "discussion 1"}, :start_date => "30-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      end

      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)
    end

  ##
  # Editar fórum (edit/update)
  ##
  
    # test "editar forum" do
    #   login(users(:aluno3))
    #   get @edition_page
    #   get(edit_discussion_path(discussions(:forum_7).id, :offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)))
    #   assert_not_nil assigns(:offer_id)
    #   assert_not_nil assigns(:group_id)
    #   assert_not_nil assigns(:discussion)
    #   assert_template :edit

    #   put("/discussions/#{discussions(:forum_7).id}/", {:discussion => {:name => "discussion 2", :description => "discussion 1"}, :start_date => "31-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids).join(" ")}.to_param)
    #   assert_equal discussions(:forum_7).schedule.start_date.strftime("%d-%m-%Y"), "31-08-2012"

    #   assert_template :list
    #   # verifica se há algum fórum de nome "discussion 2" (nome alterado de "Forum 5")
    #   assert_tag :tag => "td", :content => "\ndiscussion 2\n"
    # end

    test "nao editar forum - erro de validacao" do
      login(users(:aluno3))
      get @edition_page
      get(edit_discussion_path(discussions(:forum_7).id, :offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)))
      assert_not_nil assigns(:discussion)
      assert_template :edit

      put("/discussions/#{discussions(:forum_7).id}/", {:discussion => {:name => "discussion 2", :description => ""}, :start_date => "30-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids).join(" ")}.to_param)
      assert_not_equal discussions(:forum_7).schedule.start_date.strftime("%d-%m-%Y"), "31-08-2012"
      
      assert_template :edit

      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)}.to_param)
      # verifica se não há nenhum fórum de nome "discussion 2" (nome alterado de "Forum 5")
      assert_no_tag :tag => "td", :content => "\ndiscussion 2\n"
    end

    test "nao editar forum - sem permissao" do
      login(users(:editor))
      get @edition_page
      allocation_tags_ids = assigns(:allocation_tags_ids)

      login(users(:professor))
      get(edit_discussion_path(discussions(:forum_7).id, :offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => allocation_tags_ids))
      assert_nil assigns(:group_id)
      assert_nil assigns(:offer_id)

      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)

      put("/discussions/#{discussions(:forum_7).id}/", {:discussion => {:name => "discussion 2", :description => "discussion 1"}, :start_date => "30-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => allocation_tags_ids.join(" ")}.to_param)
      assert_not_equal discussions(:forum_7).schedule.start_date.strftime("%d-%m-%Y"), "31-08-2012"

      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)

      login(users(:aluno3))
      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => allocation_tags_ids}.to_param)
      # verifica se não há nenhum fórum de nome "discussion 2" (nome alterado de "Forum 5")
      assert_no_tag :tag => "td", :content => "\ndiscussion 2\n"
    end

  ##
  # Excluir fórum (destroy)
  ##

    # test "excluir forum" do
    #   login(users(:editor))
    #   get @edition_page
    #   get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)}.to_param)
    #   assert_not_nil assigns(:offer_id)
    #   assert_not_nil assigns(:group_id)
    #   assert_not_nil assigns(:discussions)
    #   assert_not_nil assigns(:allocation_tags_ids)
      
    #   assert_template :list

    #   assert_difference(["Discussion.count", "Schedule.count"], -1) do
    #     delete("/discussions/#{discussions(:forum_8).id}/", {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)}.to_param)
    #   end

    #   assert_template :list

    #   get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)}.to_param)
    #   # verifica se o fórum foi excluido (não deve ser exibido na página)
    #   assert_no_tag :tag => "td", :content => "\nForum 8\n"
    # end

    test "nao excluir forum - forum ja possui postagens" do
      login(users(:editor))
      get @edition_page
      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)}.to_param)

      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:discussions)
      assert_not_nil assigns(:allocation_tags_ids)

      assert_template :list

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        delete("/discussions/#{discussions(:forum_1).id}/", {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)}.to_param)
      end

      assert_template :list

      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => assigns(:allocation_tags_ids)}.to_param)

      # verifica se o fórum não foi excluido (deve ser exibido na página)
      # assert_tag :tag => "td", :content => "\nForum 1\n"
    end

    test "nao excluir forum - sem permissao" do
      login(users(:editor))
      get @edition_page
      allocation_tags_ids = assigns(:allocation_tags_ids)

      login(users(:professor))

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        delete("/discussions/#{discussions(:forum_1).id}/", {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => allocation_tags_ids}.to_param)
      end

      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)

      login(users(:editor))

      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all", :allocation_tags_ids => allocation_tags_ids}.to_param)
      # verifica se o fórum não foi excluido (deve ser exibido na página)
      assert_tag :tag => "td", :content => "\nForum 1\n"
    end
    
=end

end