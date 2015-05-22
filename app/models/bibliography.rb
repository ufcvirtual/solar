class Bibliography < ActiveRecord::Base
  include AcademicTool
  include FilesHelper

  GROUP_PERMISSION = OFFER_PERMISSION = CURRICULUM_UNIT_PERMISSION = true

  TYPE_BOOK, TYPE_PERIODICAL, TYPE_ARTICLE, TYPE_ELECTRONIC_DOC, TYPE_FREE, TYPE_FILE = 1, 2, 3, 4, 5, 6

  default_scope { order(:title, :type_bibliography) }

  has_many :authors, dependent: :destroy

  accepts_nested_attributes_for :authors, allow_destroy: true

  validates :issn, length: { is: 9 },  if: 'issn.present?' # com formatacao
  validates :isbn, length: { is: 17 }, if: 'isbn.present?' # com formatacao

  validates :title, :type_bibliography                                        , presence: true, unless: 'type_bibliography == TYPE_FILE'
  validates :address, :publisher, :edition, :publication_year                 , presence: true, if: 'type_bibliography == TYPE_BOOK'
  validates :address, :publisher, :periodicity_year_start                     , presence: true, if: 'type_bibliography == TYPE_PERIODICAL'
  validates :address, :volume, :pages, :publication_year, :publication_month  , presence: true, if: 'type_bibliography == TYPE_ARTICLE'
  validates :url, :accessed_in                                                , presence: true, if: 'type_bibliography == TYPE_ELECTRONIC_DOC'
  validates :attachment_file_name                                             , presence: true, if: 'type_bibliography == TYPE_FILE'

  has_attached_file :attachment,
    path: ":rails_root/media/bibliography/:id_:basename.:extension",
    url: "/media/bibliography/:id_:basename.:extension"

  validates_attachment_size :attachment, less_than: 5.megabyte, message: ' '
  validates_attachment_content_type_in_black_list :attachment

  before_validation proc { |record| record.errors.add(:base, I18n.t(:author_required, scope: [:bibliographies])) }, if: '[TYPE_BOOK, TYPE_ARTICLE, TYPE_ELECTRONIC_DOC].include?(type_bibliography) && authors.empty?'

  def copy_dependencies_from(bibliography_to_copy)
    copy_file(bibliography_to_copy, self, 'bibliography') if bibliography_to_copy.is_file?
  end

  def type
    btype = case type_bibliography
            when TYPE_BOOK            then 'book'
            when TYPE_PERIODICAL      then 'periodical'
            when TYPE_ARTICLE         then 'article'
            when TYPE_ELECTRONIC_DOC  then 'electronic_doc'
            when TYPE_FREE            then 'free'
            when TYPE_FILE            then 'file'
            end

    I18n.t(btype, scope: [:bibliographies, :type]) if btype
  end

  def is_file?
    type_bibliography == TYPE_FILE
  end

  def resume_authors
    authors.map(&:name).join(', ')
  end

  def resume
    btype = case type_bibliography
            when TYPE_BOOK
              r = [resume_authors]
              r << "<b>#{title}</b>"  if title
              r << subtitle           if subtitle
              r << "#{edition}. ed"   if edition
              r << "#{address}: #{publisher}, #{publication_year}" if address && publisher && publication_year
              r << "#{count_pages} p" if count_pages
              r << "v. #{volume}"     if volume
              r.join('. ')
            when TYPE_PERIODICAL
              r = ["<b>#{title}</b>"]
              r << subtitle                   if subtitle
              r << "#{address}: #{publisher}" if address && publisher
              r << periodicity_year_end ? "#{periodicity_year_start} - #{periodicity_year_end}" : periodicity_year_start
              r << periodicity                if periodicity
              r << "ISSN: #{issn}"            if issn
              r.join('. ')
            when TYPE_ARTICLE
              r = [resume_authors]
              r << "<b>#{title}</b>"         if title
              r << subtitle                  if subtitle
              r << article_periodicity_title if article_periodicity_title
              r << address                   if address
              r << "v. #{volume}"            if volume
              r << "n. #{fascicle}"          if fascicle
              r << "p. #{pages}, #{publication_month}, #{publication_year}" if pages && publication_month && publication_year
              r.join('. ')
            when TYPE_ELECTRONIC_DOC
              r = [resume_authors]
              r << "<b>#{title}</b>"      if title
              r << additional_information if additional_information
              r << "#{I18n.t(:available_in, scope: [:bibliographies, :list])} #{url}" if url
              r << "#{I18n.t(:accessed_in, scope: [:bibliographies, :list])} #{I18n.l(accessed_in, format: :bibliography)}" if accessed_in
              r.join('. ')
            when TYPE_FREE then title
            when TYPE_FILE then [attachment_file_name, "( #{format('%.2f KB', attachment_file_size/1024.0)} )"].join(' ')
            end
  end

  def self.all_by_allocation_tags(allocation_tag)
    joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: RelatedTaggable.related({group_at_id: allocation_tag}, {upper: true})}).uniq
  end

end
