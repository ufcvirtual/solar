require 'test_helper'

class  PublicFileTest < ActiveSupport::TestCase

  fixtures :public_files, :allocation_tags, :users, :groups

	test "arquivo deve ter nome" do
  	public_file = PublicFile.create(:allocation_tag_id => allocation_tags(:al3).id, :user_id => users(:aluno1).id)
  	assert (not public_file.valid?)
  	assert_equal public_file.errors[:attachment_file_name].first, "deve ser selecionado" #I18n.t(:blank, :scope => [:activerecord, :errors, :models, :assignment_file])
  end

  test "remove arquivo publico" do
    assert_difference("PublicFile.count", -1) do
      public_files(:pf4).delete_public_file
    end
  end

  test "retorna os arquivos publicos de um aluno em uma turma" do 
  	all_public_files_method = PublicFile.all_by_class_id_and_user_id(groups(:g3).id, users(:aluno1).id)
		all_public_files = PublicFile.all(:conditions => ["users.id = #{users(:aluno1).id} AND allocation_tags.group_id = #{groups(:g3).id}"], :include => [:allocation_tag, :user], :select => ["attachment_file_name, attachment_content_type, attachment_file_size, attachment_updated_at"])
		assert_equal(all_public_files_method, all_public_files)
  end

end
