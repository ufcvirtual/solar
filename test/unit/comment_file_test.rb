require 'test_helper'

class  CommentFileTest < ActiveSupport::TestCase

	test "arquivo deve ter nome" do
  	comment_file = CommentFile.create(:assignment_comment_id => assignment_comments(:ac2).id)
  	assert (not comment_file.valid?)
  	assert_equal comment_file.errors[:attachment_file_name].first, I18n.t(:blank, scope: [:activerecord, :errors, :messages])
  end

  test "arquivo valido" do
    comment_file = CommentFile.create(assignment_comment_id: assignment_comments(:ac2).id, attachment: fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain'))
    assert comment_file.valid?
  end

end
