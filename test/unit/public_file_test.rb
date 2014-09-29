require 'test_helper'

class  PublicFileTest < ActiveSupport::TestCase

  test "arquivo deve ter nome" do
    public_file = PublicFile.create(:allocation_tag_id => allocation_tags(:al3).id, :user_id => users(:aluno1).id)
    assert (not public_file.valid?)
    assert_equal public_file.errors[:attachment_file_name].first, "deve ser selecionado" #I18n.t(:blank, :scope => [:activerecord, :errors, :models, :assignment_file])
  end

  test "remove arquivo publico" do
    assert_difference("PublicFile.count", -1) do
      public_files(:pf4).delete
    end
  end

   test "arquivo valido" do
    public_file = PublicFile.create(:allocation_tag_id => allocation_tags(:al3).id, :user_id => users(:aluno1).id, :attachment => fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain'))
    assert public_file.valid?
  end

end
