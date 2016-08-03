class Question < ActiveRecord::Base

  include FilesHelper

  UNIQUE, MULTIPLE, TRUE_FALSE = 0, 1, 2

  belongs_to  :user
  belongs_to :updated_by_user, class_name: 'User'

  has_many :exam_questions
  has_many :exam_responses
  has_many :exams, through: :exam_questions
  has_many :question_images, class_name: 'QuestionImage', dependent: :destroy
  has_many :question_items , class_name: 'QuestionItem' , dependent: :destroy

  has_and_belongs_to_many :question_labels

  accepts_nested_attributes_for :question_images, allow_destroy: true, reject_if: :reject_images
  accepts_nested_attributes_for :question_labels, allow_destroy: true, reject_if: :reject_labels
  accepts_nested_attributes_for :question_items, allow_destroy: true, reject_if: :reject_items

  validates :enunciation, :type_question, presence: true

  validate :verify_labels, :verify_images

  before_destroy :can_destroy?
  before_destroy { question_labels.clear }

  before_save :get_labels

  def reject_images(img)
    (img[:image].blank? && (new_record? || img[:id].blank?))
  end

  def reject_labels(label)
    (label[:name].blank? && (new_record? || label[:id].blank?))
  end

  def reject_items(item)
    (item[:description].blank? && (new_record? || item[:id].blank?))
  end

  def get_labels
    self.question_labels = self.question_labels.collect do |label|
      QuestionLabel.find_or_create_by_name(label.name)
    end
  end

  def copy_dependencies_from(question_to_copy, user_id = nil)
    if question_to_copy.question_images.any?
      question_to_copy.question_images.each do |file|
        new_file = QuestionImage.create! file.attributes.merge({ question_id: id })
        copy_file(file, new_file, File.join('questions', 'images'), 'image')
      end
    end
    if question_to_copy.question_items.any?
      question_to_copy.question_items.each do |item|
        new_item = QuestionItem.create! item.attributes.merge({ question_id: id })
        copy_file(item, new_item, File.join('questions', 'items'), 'item_image') unless new_item.item_image_file_name.nil?
      end
    end
    if question_to_copy.question_labels.any?
      question_to_copy.question_labels.each do |label|
        question_labels << label
      end
    end
  end

  def self.copy(question_to_copy, user_id = nil)
    attributes = (user_id != question_to_copy.user_id ? { updated_by_user_id: user_id } : {})
    question   = Question.create question_to_copy.attributes.except('id', 'updated_by_user_id').merge(attributes)
    question.copy_dependencies_from(question_to_copy, user_id)
    question
  end

  def type
    case type_question
    when UNIQUE     then I18n.t('questions.types.unique_choice')
    when MULTIPLE   then I18n.t('questions.types.multiple_choice')
    when TRUE_FALSE then I18n.t('questions.types.true_or_false')
    else
     ''
    end
  end

  def self.get_all(user_id, search={}, verify_privacy=false)
    query = []

    query << ((search[:only_owner] == 'false' || search[:only_owner].blank?) ? (!verify_privacy.nil? && verify_privacy ? "
              (authors.id = #{user_id}
              OR (
               ((SELECT count FROM user_public_questions) = 0 AND (SELECT count FROM user_private_questions) = 0) 
               OR ((SELECT count FROM user_public_questions) >= (SELECT count FROM user_private_questions)/10)
              ))" : '') : "authors.id = #{user_id}")

    query << "lower(unaccent(questions.enunciation)) ~ lower(unaccent('#{search[:enun].to_s}'))" unless search[:enun].blank?
    query << "lower(unaccent(l1.name)) ~ lower(unaccent('#{search[:label].to_s}'))"              unless search[:label].blank?
    query << "date_part('year', questions.updated_at) = '#{search[:year].to_s}'"                 unless search[:year].blank?
    query << "lower(unaccent(authors.name)) ~ lower(unaccent('#{search[:author].to_s}'))"        unless search[:author].blank?
    query << "lower(unaccent(updated_by.name)) ~ lower(unaccent('#{search[:author].to_s}'))" unless search[:author].blank?

    query = query.reject(&:empty?)

    query = query.empty? ? '' : ['WHERE', query.join(' AND ')].join(' ')

    Question.find_by_sql <<-SQL
      WITH user_private_questions AS (
        SELECT COUNT(questions.id) AS count FROM questions
        WHERE  questions.privacy = 't' AND questions.status = 't' AND questions.user_id = #{user_id}
      ),   user_public_questions AS (
        SELECT COUNT(questions.id) AS count FROM questions
        WHERE  questions.privacy = 'f' AND questions.status = 't' AND questions.user_id = #{user_id}
      )
      SELECT  DISTINCT questions.id,
              questions.enunciation, 
              questions.type_question, 
              questions.status, 
              questions.updated_at,
              questions.privacy,
              authors.name                                        AS author_name,
              updated_by.name                                     AS updated_by_name,
              COALESCE(COUNT(DISTINCT exam_questions.exam_id), 0) AS count_exams,
              (
                SELECT COUNT(question_items.id)
                FROM question_items
                WHERE question_items.question_id = questions.id
              )                                    AS count_items,
              EXISTS(
                SELECT question_images.id 
                FROM question_images 
                WHERE questions.id = question_images.question_id
              )                                    AS has_images,
              replace(replace(translate(array_agg(distinct l2.name)::text,'{}', ''),'\"', ''),',',', ') AS labels
              FROM questions
              LEFT JOIN users AS authors    ON questions.user_id = authors.id
              LEFT JOIN users AS updated_by ON questions.updated_by_user_id   = updated_by.id
              LEFT JOIN exam_questions      ON exam_questions.question_id     = questions.id
              LEFT JOIN question_labels_questions AS qlq1 ON qlq1.question_id = questions.id
              LEFT JOIN question_labels_questions AS qlq2 ON qlq2.question_id = questions.id
              LEFT JOIN question_labels           AS l1  ON l1.id = qlq1.question_label_id
              LEFT JOIN question_labels           AS l2  ON l2.id = qlq2.question_label_id
              #{query}
              GROUP BY questions.id, questions.enunciation, questions.type_question, questions.status, questions.updated_at, questions.privacy, authors.name, updated_by.name;
    SQL
  end

  def verify_labels
    errors.add(:base, I18n.t('questions.error.max_labels')) if question_labels.size > 8
  end

  def verify_images
    errors.add(:base, I18n.t('questions.error.max_images')) if question_images.size > 4
  end

  def can_destroy?
    raise 'permission' unless owner?
    raise 'in_use'     if exams.any?
  end

  def can_change_status?
    raise 'permission' unless owner?
    raise 'in_use'     if exams.any? && status # if in use and already published
    validate_items
  end

  def validate_items
    if !status
      raise 'min_items'     if question_items.size < 3
      raise 'correct_item'  if question_items.where(value: true).empty?
      raise 'only_one_true' if type_question == 0 && question_items.where(value: true).size > 1
    end
  end

  def can_see?(boolean=false)
    result = !privacy || owners?
    raise 'permission' unless boolean || result
    result
  end

  def can_change?
    raise 'permission' unless owner?
    raise 'in_use'     if exams.any? && status # if in use and already published
  end

  def owner?(s = false)
    if s
      (self.updated_by_user_id.nil? ? self.user_id == User.current.id : self.updated_by_user_id == User.current.id)
    else
      (updated_by_user_id.nil? ? user_id == User.current.id : updated_by_user_id == User.current.id)
    end
  end

  def owners?(s = false)
    if s
      (self.user_id == User.current.id || self.updated_by_user_id == User.current.id)
    else
      (user_id == User.current.id || updated_by_user_id == User.current.id)
    end
  end

  def in_use?
    exams.any?
  end

  def validate_images
    errors.add(:base, I18n.t('questions.error.max_images')) if question_images.any? && question_images.size > 4
  end

  def can_import_or_export?(current_user, exam = nil)
    raise 'private' unless !privacy || owners?(true)
    user_questions    = current_user.questions
    user_up_questions = current_user.up_questions
    raise 'min_public_questions' if !owners?(true) && !user_questions.empty? && ((user_questions.where(privacy: true).count/user_questions.where(privacy: false).count > 10 rescue false) || (user_up_questions.where(privacy: true).count/user_up_questions.where(privacy: false).count > 10 rescue false))
    raise 'draft' if !privacy && !owner?(true) && !status 
    raise 'already_exists' if !exam.nil? && exam.questions.where(id: id).any?
  end

  def can_destroy?
    raise 'permission' unless owner?
    raise 'in_use'     if exams.any?
  end

  def can_copy?
    raise 'private' unless !privacy || owners?
  end

  def log_description
    desc = {}

    desc.merge!(attributes.except('attachment_updated_at', 'updated_at', 'created_at', 'id'))
    desc.merge!(images: question_images.collect{|img| img.attributes.except('image_updated_at' 'question_id')})
    desc.merge!(items: question_items.collect{|item| item.attributes.except('question_id', 'item_image_updated_at')})
    desc.merge!(labels: question_labels.collect{|item| item.attributes.except('created_at', 'updated_at')})
  end

end
