require 'test_helper'

class SupportMaterialFilesControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  def setup
    sign_in users(:editor)
  end

  test "rotas" do
    assert_routing "/support_material_files", {controller: "support_material_files", action: "index"}
    assert_routing "/support_material_files/list", {controller: "support_material_files", action: "list"}
    assert_routing "/support_material_files/at/3/download", {controller: "support_material_files", action: "download", type: :all, allocation_tag_id: "3"}
    assert_routing "/support_material_files/at/3/folder/GERAL/download", {controller: "support_material_files", action: "download", type: :folder, allocation_tag_id: "3", folder: "GERAL"}
  end

  test "listar material para edicao" do
    get :list, {allocation_tags_ids: "#{allocation_tags(:al3).id}"}
    assert_response :success
    assert_not_nil assigns(:allocation_tags_ids)
    assert_not_nil assigns(:support_materials)
  end

  test "criar material do tipo link com protocolo default" do
    assert_difference(["SupportMaterialFile.count", "AcademicAllocation.count"], 2) do
      post(:create, {support_material_file: {url: "google.com", material_type: Material_Type_Link}, allocation_tags_ids: "#{allocation_tags(:al3).id}"}) #turma
      post(:create, {support_material_file: {url: "google.com", material_type: Material_Type_Link}, allocation_tags_ids: "#{allocation_tags(:al6).id}"}) #oferta
    end
    assert_response :success
    assert_equal SupportMaterialFile.last.url, "http://google.com"
  end

  test "criar material do tipo arquivo" do
    assert_difference(["SupportMaterialFile.count", "AcademicAllocation.count"], 1) do
      post(:create, {files: [fixture_file_upload('files/file_10k.dat')], support_material_file: {material_type: Material_Type_File}, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end
    assert_response :success
  end

  test "nao criar novo material para uc ou curso" do
    # tentando criar para a UC de quimica 3 e o curso de licenciatura em quimica
    assert_no_difference(["SupportMaterialFile.count", "AcademicAllocation.count"]) do
      post(:create, {support_material_file: {url: "google.com", material_type: Material_Type_Link}, allocation_tags_ids: "#{allocation_tags(:al13).id}"})
      post(:create, {support_material_file: {url: "google.com", material_type: Material_Type_Link}, allocation_tags_ids: "#{allocation_tags(:al19).id}"})
    end

    assert_response :unprocessable_entity
  end

  test "download" do
    assert_difference(["SupportMaterialFile.count", "AcademicAllocation.count"], 1) do
      post(:create, {files: [fixture_file_upload('files/file_10k.dat')], support_material_file: {material_type: Material_Type_File}, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end

    get(:download, {id: SupportMaterialFile.last.id, allocation_tag_id: allocation_tags(:al3).id})
    assert_response :success
  end

  test "editar" do
    assert_difference(["SupportMaterialFile.count", "AcademicAllocation.count"], 1) do
      post(:create, {support_material_file: {url: "google.com", material_type: Material_Type_Link}, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end

    last_material = SupportMaterialFile.last
    assert_equal last_material.url, "http://google.com"

    assert_no_difference(["SupportMaterialFile.count", "AcademicAllocation.count"]) do
      put(:update, {id: last_material.id, support_material_file: {url: "youtube.com"}, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end

    assert_equal "http://youtube.com", SupportMaterialFile.last.url
  end

  test "deletar" do
    assert_difference(["SupportMaterialFile.count", "AcademicAllocation.count"], 1) do
      post(:create, {support_material_file: {url: "google.com", material_type: Material_Type_Link}, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end

    assert_difference(["SupportMaterialFile.count", "AcademicAllocation.count"], -1) do
      delete(:destroy, {id: SupportMaterialFile.last.id, allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end
  end

  test "deletar varios materiais" do
    materials = [support_material_files(:arquivo7), support_material_files(:url2), support_material_files(:url3)]
    assert_difference(["SupportMaterialFile.count", "AcademicAllocation.count"], -materials.count) do
      delete(:destroy, {id: materials.map(&:id), allocation_tags_ids: "#{allocation_tags(:al3).id}"})
    end
  end

end
