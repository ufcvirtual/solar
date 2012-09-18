require 'test_helper'

class  PublicFileTest < ActiveSupport::TestCase

  fixtures :public_files, :allocation_tags, :users

	test "arquivo deve ter nome" do
  	public_file = PublicFile.create(:allocation_tag_id => allocation_tags(:al3).id, :user_id => users(:aluno1))
  	assert (not public_file.valid?)
  	assert_equal public_file.errors[:attachment_file_name].first, "deve ser selecionado" #I18n.t(:blank, :scope => [:activerecord, :errors, :models, :assignment_file])
  end

  #  test "arquivo deve ter tamanho menor do que 5 megas" do 
  # 	public_file = PublicFile.create(public_files(:pf1))
  # 	assert public_file.valid?

  # 	public_file = PublicFile.create(public_files(:pf2))
  # 	assert public_file.valid?
  # end


end
