class SentAssignment < ActiveRecord::Base

  belongs_to :user
  belongs_to :assignment
  belongs_to :group_assignment

  has_many :assignment_comments, :dependent => :destroy
  has_many :assignment_files

  validates :grade, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10, :allow_blank => true}

  before_save :if_group_assignment_remove_user_id

  ## 
  # Em situações de trabalho em grupo avaliado a partir de links que tenham um id do aluno, remover o id do aluno no momento de salvar o sent_assignment
  ##
  def if_group_assignment_remove_user_id
  	if group_assignment_id
  		self.user_id = nil
  	end
  end

end
