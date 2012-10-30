require 'test_helper'
 
# Aqui estão os testes dos métodos do cotnroller discussions
# que, ao executá-los, são feitas alterações em schedules. 
# Há, também, o método index que precisa estar em uma allocation_tag
# para poder ser executado.

class AssignmentsWithAllocationTagTest < ActionDispatch::IntegrationTest
  fixtures :all
  # para poder realizar o "login_as" sabendo que o sign_in do devise não funciona no teste de integração
  include Warden::Test::Helpers 
  
  def setup
    @quimica_tab = "/application/add_tab/3?allocation_tag_id=3&context=2"
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
      login(users(:coorddisc))
      get @quimica_tab
      get discussions_path
      assert_nil assigns(:discussions)
      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)
    end

  ##
  # Novo fórum (new/create)
  ##
  
    test "criar novo forum" do
      login(users(:coorddisc))
      get(new_discussion_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:discussion)
      assert_template :new

      assert_difference(["Discussion.count", "Schedule.count"], +(offers(:of3).groups.size)) do
        post("/discussions/", {:discussion => {:name => "discussion 1", :description => "discussion 1"}, :start_date => "30-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      end

      assert_response :redirect
      assert_redirected_to(list_discussions_url)
      assert_equal( flash[:notice], I18n.t(:created, :scope => [:discussion, :success]) )
    end

    test "nao criar novo forum - erro de validacao" do
      login(users(:coorddisc))
      get(new_discussion_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:discussion)
      assert_template :new

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        post("/discussions/", {:discussion => {:description => "discussion 1"}, :start_date => "30-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      end

      assert_template :new
    end

    test "nao criar novo forum - sem permissao" do
      login(users(:professor))
      get(new_discussion_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
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
  
    test "editar forum" do
      login(users(:coorddisc))
      get(edit_discussion_path(discussions(:forum_7).id, :offer_id => offers(:of3).id, :group_id => "all"))
      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:discussion)
      assert_template :edit

      put("/discussions/#{discussions(:forum_7).id}/", {:discussion => {:name => "discussion 2", :description => "discussion 1"}, :start_date => "31-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      assert_equal discussions(:forum_7).schedule.start_date.strftime("%d-%m-%Y"), "31-08-2012"

      assert_response :redirect
      assert_redirected_to(list_discussions_url)
      assert_equal( flash[:notice], I18n.t(:updated, :scope => [:discussion, :success]) )

      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      # verifica se há algum fórum de nome "discussion 2" (nome alterado de "Forum 5")
      assert_tag :tag => "table", 
      :attributes => { :class => "tb_list" },
      :child => { 
        :tag => "tbody",
        :child => {
          :tag => "tr", 
          :child => {
            :tag => "td",
            :child => {
              :tag => "a",
              :content => "discussion 2"
            } #child td
          } # child tr
        } # child tbody
     } # child table
    end

    test "nao editar forum - erro de validacao" do
      login(users(:coorddisc))
      get(edit_discussion_path(discussions(:forum_7).id, :offer_id => offers(:of3).id, :group_id => "all"))
      assert_not_nil assigns(:discussion)
      assert_template :edit

      put("/discussions/#{discussions(:forum_7).id}/", {:discussion => {:name => "discussion 2", :description => ""}, :start_date => "30-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      assert_not_equal discussions(:forum_7).schedule.start_date.strftime("%d-%m-%Y"), "31-08-2012"
      
      assert_template :edit

      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      # verifica se não há nenhum fórum de nome "discussion 2" (nome alterado de "Forum 5")
      assert_no_tag :tag => "table", 
      :attributes => { :class => "tb_list" },
      :child => { 
        :tag => "tbody",
        :child => {
          :tag => "tr", 
          :child => {
            :tag => "td",
            :child => {
              :tag => "a",
              :content => "discussion 2"
            } #child td
          } # child tr
        } # child tbody
     } # child table
    end

    test "nao editar forum - sem permissao" do
      login(users(:professor))
      get(edit_discussion_path(discussions(:forum_7).id, :offer_id => offers(:of3).id, :group_id => "all"))
      assert_nil assigns(:group_id)
      assert_nil assigns(:offer_id)

      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)

      put("/discussions/#{discussions(:forum_7).id}/", {:discussion => {:name => "discussion 2", :description => "discussion 1"}, :start_date => "30-08-2012", :end_date => "30-11-2012", :offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      assert_not_equal discussions(:forum_7).schedule.start_date.strftime("%d-%m-%Y"), "31-08-2012"

      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)

      login(users(:coorddisc))
      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      # verifica se não há nenhum fórum de nome "discussion 2" (nome alterado de "Forum 5")
      assert_no_tag :tag => "table", 
      :attributes => { :class => "tb_list" },
      :child => { 
        :tag => "tbody",
        :child => {
          :tag => "tr", 
          :child => {
            :tag => "td",
            :child => {
              :tag => "a",
              :content => "discussion 2"
            } #child td
          } # child tr
        } # child tbody
     } # child table
    end

  ##
  # Excluir fórum (destroy)
  ##

    test "excluir forum" do
      login(users(:coorddisc))
      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:discussions)
      assert_not_nil assigns(:responsible_or_student)
      assert_not_nil assigns(:group_code)
      assert_not_nil assigns(:offer_semester)
      
      assert_template :list

      assert_difference(["Discussion.count", "Schedule.count"], -1) do
        delete("/discussions/#{discussions(:forum_8).id}/", {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      end

      assert_response :redirect
      assert_redirected_to(list_discussions_url)
      assert_equal( flash[:notice], I18n.t(:deleted, :scope => [:discussion, :success]) )

      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      # verifica se há algum fórum de nome "discussion 2" (nome alterado de "Forum 5")
      assert_no_tag :tag => "table", 
      :attributes => { :class => "tb_list" },
      :child => { 
        :tag => "tbody",
        :child => {
          :tag => "tr", 
          :child => {
            :tag => "td",
            :child => {
              :tag => "a",
              :content => "Forum 6"
            } #child td
          } # child tr
        } # child tbody
     } # child table
    end

    test "nao excluir forum - forum ja possui postagens" do
      login(users(:coorddisc))
      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      assert_not_nil assigns(:offer_id)
      assert_not_nil assigns(:group_id)
      assert_not_nil assigns(:discussions)
      assert_not_nil assigns(:responsible_or_student)
      assert_not_nil assigns(:group_code)
      assert_not_nil assigns(:offer_semester)
      
      assert_template :list

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        delete("/discussions/#{discussions(:forum_1).id}/", {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      end

      assert_response :redirect
      assert_redirected_to(list_discussions_url)
      assert_equal( flash[:alert], I18n.t(:cant_delete, :scope => [:discussion, :errors]) )

      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      # verifica se há algum fórum de nome "discussion 2" (nome alterado de "Forum 5")
      assert_tag :tag => "table", 
      :attributes => { :class => "tb_list" },
      :child => { 
        :tag => "tbody",
        :child => {
          :tag => "tr", 
          :child => {
            :tag => "td",
            :child => {
              :tag => "a",
              :content => "Forum 1"
            } #child td
          } # child tr
        } # child tbody
     } # child table
    end

    test "nao excluir forum - sem permissao" do
      login(users(:professor))

      assert_no_difference(["Discussion.count", "Schedule.count"]) do
        delete("/discussions/#{discussions(:forum_1).id}/", {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      end

      assert_redirected_to({:controller => :home})
      assert_equal flash[:alert], I18n.t(:no_permission)

      login(users(:coorddisc))

      get(list_discussions_path, {:offer_id => offers(:of3).id, :group_id => "all"}.to_param)
      # verifica se há algum fórum de nome "discussion 2" (nome alterado de "Forum 5")
      assert_tag :tag => "table", 
      :attributes => { :class => "tb_list" },
      :child => { 
        :tag => "tbody",
        :child => {
          :tag => "tr", 
          :child => {
            :tag => "td",
            :child => {
              :tag => "a",
              :content => "Forum 1"
            } #child td
          } # child tr
        } # child tbody
     } # child table
    end


end