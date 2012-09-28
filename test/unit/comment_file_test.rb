require 'test_helper'

class  CommentFileTest < ActiveSupport::TestCase

  # para reconhecer o método "fixture_file_upload" no teste de unitário
  include ActionDispatch::TestProcess

  fixtures :comment_files, :assignment_comments, :users

	test "arquivo deve ter nome" do
  	comment_file = CommentFile.create(:assignment_comment_id => assignment_comments(:ac2).id)
  	assert (not comment_file.valid?)
  	assert_equal comment_file.errors[:attachment_file_name].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "remove arquivo de comentario" do
    assert_difference("CommentFile.count", -1) do
      comment_files(:acf3).delete_comment_file
    end
  end

  test "arquivo valido" do
    comment_file = CommentFile.create(:assignment_comment_id => assignment_comments(:ac2).id, :attachment => fixture_file_upload('files/assignments/comment_files/teste1.txt', 'text/plain'))
    assert comment_file.valid?
  end

end
