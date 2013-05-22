require 'test_helper'

class SupportMaterialFileTest < ActiveSupport::TestCase

  include ActionDispatch::TestProcess
  fixtures :support_material_files

  def setup
    @at_quimica1 = allocation_tags(:al3).id
  end

  test "criar material do tipo link com protocolo default" do
    assert_difference("SupportMaterialFile.count", 1) do 
      SupportMaterialFile.create url: "google.com", allocation_tag_id: @at_quimica1, material_type: Material_Type_Link
    end

    assert_equal SupportMaterialFile.last.url, "http://google.com"
  end

  test "criar material do tipo arquivo" do
    material = SupportMaterialFile.new attachment: fixture_file_upload('files/file_10k.dat'), allocation_tag_id: @at_quimica1
    assert_difference("SupportMaterialFile.count", 1) do 
      material.save
    end
  end

  test "nao criar material do tipo arquivo por tamanho de arquivo" do
    material = SupportMaterialFile.new attachment: fixture_file_upload('files/file_10m.dat'), allocation_tag_id: @at_quimica1
    assert_no_difference("SupportMaterialFile.count") do 
      material.save
    end

    assert_equal material.errors.full_messages.join.strip, I18n.t("activerecord.attributes.support_material_file.attachment_file_size").strip
  end

  test "editar" do
    s = support_material_files(:url4)

    assert_equal s.url, "http://www.prograd.ufc.br"
    s.url = "www.google.com"

    assert s.save
    assert_equal s.url, "http://www.google.com"
  end

  test "deletar" do
    assert_difference("SupportMaterialFile.count", -1) do
      support_material_files(:arquivo1).destroy
    end
  end

end
