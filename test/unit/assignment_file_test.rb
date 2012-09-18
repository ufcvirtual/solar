require 'test_helper'

class  AssignmentFileTest < ActiveSupport::TestCase

  fixtures :assignment_files, :send_assignments, :users

  test "arquivo deve ter nome" do
  	assignment_file = AssignmentFile.create(:send_assignment_id => send_assignments(:sa2).id, :user_id => users(:aluno1))
  	assert (not assignment_file.valid?)
  	assert_equal assignment_file.errors[:attachment_file_name].first, "deve ser selecionado" #I18n.t(:blank, :scope => [:activerecord, :errors, :models, :assignment_file])
  end

end
