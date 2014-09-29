require 'test_helper'

class  AssignmentFileTest < ActiveSupport::TestCase

  test "arquivo deve ter nome" do
  	assignment_file = AssignmentFile.create(:sent_assignment_id => sent_assignments(:sa2).id, :user_id => users(:aluno1).id)
  	assert not(assignment_file.valid?)
  	assert_equal assignment_file.errors[:attachment_file_name].first, "deve ser selecionado" #I18n.t(:blank, :scope => [:activerecord, :errors, :models, :assignment_file])
  end

  test "arquivo valido" do
    assignment_file = AssignmentFile.create(:sent_assignment_id => sent_assignments(:sa2).id, :user_id => users(:aluno1).id, :attachment => fixture_file_upload('files/assignments/sent_assignment_files/teste1.txt', 'text/plain'))
    assert assignment_file.valid?
  end

end
