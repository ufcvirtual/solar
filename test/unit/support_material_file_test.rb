require 'test_helper'

class SupportMaterialFileTest < ActiveSupport::TestCase

  include ActionDispatch::TestProcess

  test "criar material do tipo link com protocolo default" do
    assert_difference("SupportMaterialFile.count", 1) do 
      SupportMaterialFile.create url: "google.com", material_type: Material_Type_Link
    end

    assert_equal SupportMaterialFile.last.url, "http://google.com"
  end

  test "criar material do tipo arquivo" do
    material = SupportMaterialFile.new attachment: fixture_file_upload('files/file_10k.dat')
    assert_difference("SupportMaterialFile.count", 1) do 
      material.save
    end

    assert material.valid?
  end

  test "nao criar material com tipo invalido" do
    material = SupportMaterialFile.new attachment: fixture_file_upload('files/file_10k.exe')
    assert_no_difference("SupportMaterialFile.count") do 
      material.save
    end
    
    assert material.invalid?
    assert material.errors.full_messages.join.strip.include?(I18n.t("activerecord.attributes.support_material_file.attachment_content_type").strip)
  end

  test "nao criar material do tipo arquivo por tamanho de arquivo" do
    material = SupportMaterialFile.new attachment: fixture_file_upload('files/file_40m.dat')
    assert_no_difference("SupportMaterialFile.count") do 
      material.save
    end

    assert material.invalid?
    assert_equal material.errors.full_messages.join.strip, I18n.t("activerecord.attributes.support_material_file.attachment_file_size").strip
  end

  test "material deve ter url valida se for de link" do
    material = SupportMaterialFile.create(material_type: Material_Type_Link)

    assert not(material.valid?)
    assert_equal material.errors[:url].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])

    material = SupportMaterialFile.create(material_type: Material_Type_Link, url: "google")

    assert not(material.valid?)
    assert_equal I18n.t(:invalid, :scope => [:activerecord, :errors, :messages]), material.errors[:url].first
  end

  test "criando material completando a url com http quando necessario" do
    material = SupportMaterialFile.create(material_type: Material_Type_Link, url: "www.google.com")
    
    assert material.valid?
    assert_equal "http://www.google.com", material.url

    material = SupportMaterialFile.create(material_type: Material_Type_Link, url: "https://www.google.com")
    
    assert material.valid?
    assert_equal "https://www.google.com", material.url
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
