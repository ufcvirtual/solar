class ExamUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :academic_allocation

  has_many :exam_responses, dependent: :destroy
  has_many :question_items, through: :exam_responses
  has_many :questions     , through: :question_items


  def questions_answereds
    questions = ExamUser.find_by_sql  <<-SQL

        SELECT COUNT(*) FROM
          (
            SELECT DISTINCT question_id 
            FROM question_items
            JOIN exam_responses ON exam_responses.question_item_id = question_items.id
            JOIN exam_users     ON exam_responses.exam_user_id     = exam_users.id
            WHERE exam_users.id = #{id}
          ) AS questiones

    SQL

    questions.first[:count]
  end

  def self.get_grade(ac_id, user_id)
    exam_users = ExamUser.where(user_id: user_id, academic_allocation_id: ac_id)
    return nil unless exam_users.any?

    if exam_users.size == 1
      return exam_users.first.get_grade
    else
      complete = exam_users.where(complete: true).order('updated_at DESC')
      return (complete.empty? ? exam_users : complete).first.get_grade
    end

    return nil
  end

  def get_grade
    # se a prova tiver sido encerrada
    grade || set_grade
  end

  def set_grade
    0
    # calcular a nota 


  end

end


