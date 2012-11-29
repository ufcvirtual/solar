require 'test_helper'

class LessonsControllerTest < ActionController::TestCase

  include Devise::TestHelpers
  fixtures :lessons, :allocation_tags

  def setup
    @editor    = users(:editor)
    @professor = users(:professor)
    sign_in @editor
  end


  ##
  # Download_files
  ##

  # Usuário com permissão
  test "permitir zipar e realizar download de arquivos de aulas" do
    lessons_ids = [lessons(:pag_ufc).id.to_s, lessons(:pag_uol).id.to_s]

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
    assert_response :success

    zip_name = Digest::SHA1.hexdigest(lessons_ids.collect{ |lesson_id| File.join(Rails.root.to_s, 'media', 'lessons', lesson_id) }.join) << '.zip'
    assert File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name))
  end

  # Usuário com permissão, mas não selecionou nenhuma aula # CONCLUIR
  test "nao permitir zipar e realizar download de arquivos de aulas se nenhuma for selecionada" do
    lessons_ids = []

    get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
    # assert_template :list
    # assert_redirected_to({:controller => :lessons, :action => :list, :allocation_tag_id => assigns(:allocation_tags_ids)})
    # assert_redirected_to( list_lessons_url(:allocation_tag_id => assigns(:allocation_tags_ids)) )
    assert_equal I18n.t(:must_select_lessons, :scope => [:lessons, :notifications]), flash[:alert]

    zip_name = Digest::SHA1.hexdigest(lessons_ids.collect{ |lesson_id| File.join(Rails.root.to_s, 'media', 'lessons', lesson_id) }.join) << '.zip'
    assert (not File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name)))
  end

  # Usuário com permissão, mas sem acesso às aulas selecionadas # INICIAR
  # test "nao permitir zipar e realizar download de arquivos de aulas se nenhuma for selecionada" do
  #   lessons_ids = []

  #   get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
  #   # assert_template :list
  #   # assert_redirected_to({:controller => :lessons, :action => :list, :allocation_tag_id => assigns(:allocation_tags_ids)})
  #   # assert_redirected_to( list_lessons_url(:allocation_tag_id => assigns(:allocation_tags_ids)) )
  #   assert_equal flash[:alert], I18n.t(:must_select_lessons, :scope => [:lessons, :notifications])

  #   zip_name = Digest::SHA1.hexdigest(lessons_ids.collect{ |lesson_id| File.join(Rails.root.to_s, 'media', 'lessons', lesson_id) }.join) << '.zip'
  #   assert (not File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name)))
  # end

  # # Usuário sem permissão # CONCLUIR
  # test "nao permitir zipar e realizar download de arquivos de aulas para usuario sem permissao" do
  #   sign_out @editor
  #   sign_in @professor

  #   lessons_ids = [lessons(:pag_ufc).id.to_s, lessons(:pag_uol).id.to_s]

  #   get(:download_files, {:lessons_ids => lessons_ids, :allocation_tags_ids => [allocation_tags(:al6)]})
  #   assert_redirected_to({:controller => :home})
  #   assert_equal I18n.t(:no_permission), flash[:alert]

  #   zip_name = Digest::SHA1.hexdigest(lessons_ids.collect{ |lesson_id| File.join(Rails.root.to_s, 'media', 'lessons', lesson_id) }.join) << '.zip'
  #   assert (not File.exists?(File.join(Rails.root.to_s, 'tmp', zip_name)))
  # end

end
