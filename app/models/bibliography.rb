class Bibliography < ActiveRecord::Base

  GROUP_PERMISSION = OFFER_PERMISSION = CURRICULUM_UNIT_PERMISSION = true

  TYPE_BOOK, TYPE_PERIODICAL, TYPE_ARTICLE, TYPE_ELECTRONIC_DOC, TYPE_FREE = 1, 2, 3, 4, 5

  default_scope {order(:title, :type_bibliography)}

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :authors, dependent: :destroy

  accepts_nested_attributes_for :authors, allow_destroy: true

  validates :title, :type_bibliography, presence: true
  validates :issn, length: {is: 9}, if: "issn.present?" # com formatacao
  validates :isbn, length: {is: 17}, if: "isbn.present?" # com formatacao

  validates :address, :publisher, :edition, :publication_year                 , presence: true, if: "type_bibliography == TYPE_BOOK"
  validates :address, :publisher, :periodicity_year_start                     , presence: true, if: "type_bibliography == TYPE_PERIODICAL"
  validates :address, :volume, :pages, :publication_year, :publication_month  , presence: true, if: "type_bibliography == TYPE_ARTICLE"
  validates :url, :accessed_in                                                , presence: true, if: "type_bibliography == TYPE_ELECTRONIC_DOC"

  before_validation proc { |record| record.errors.add(:base, I18n.t(:author_required, scope: [:bibliographies])) }, if: "[TYPE_BOOK, TYPE_ARTICLE, TYPE_ELECTRONIC_DOC].include?(type_bibliography) and authors.empty?"

  def type
    btype = case type_bibliography
    when TYPE_BOOK
      "book"
    when TYPE_PERIODICAL
      "periodical"
    when TYPE_ARTICLE
      "article"
    when TYPE_ELECTRONIC_DOC
      "electronic_doc"
    when TYPE_FREE
      "free"
    end

    I18n.t(btype, scope: [:bibliographies, :type]) if btype
  end

  def resume_authors
    authors.map(&:name).join(", ")
  end

  def resume
    btype = case type_bibliography
    when TYPE_BOOK
      r = [resume_authors]
      r << "<b>#{title}</b>" if title
      r << subtitle if subtitle
      r << "#{edition}. ed" if edition
      r << "#{address}: #{publisher}, #{publication_year}" if address and publisher and publication_year
      r << "#{count_pages} p" if count_pages
      r << "v. #{volume}" if volume
      r.join(". ")
    when TYPE_PERIODICAL
      r = ["<b>#{title}</b>"]
      r << subtitle if subtitle
      r << "#{address}: #{publisher}" if address and publisher
      r << periodicity_year_end ? "#{periodicity_year_start} - #{periodicity_year_end}" : periodicity_year_start
      r << periodicity if periodicity
      r << "ISSN: #{issn}" if issn
      r.join(". ")
    when TYPE_ARTICLE
      r = [resume_authors]
      r << "<b>#{title}</b>" if title
      r << subtitle if subtitle
      r << article_periodicity_title if article_periodicity_title
      r << address if address
      r << "v. #{volume}" if volume
      r << "n. #{fascicle}" if fascicle
      r << "p. #{pages}, #{publication_month}, #{publication_year}" if pages and publication_month and publication_year
      r.join(". ")
    when TYPE_ELECTRONIC_DOC
      r = [resume_authors]
      r << "<b>#{title}</b>" if title
      r << additional_information if additional_information
      r << "#{I18n.t(:available_in, scope: [:bibliographies, :list])} #{url}" if url
      r << "#{I18n.t(:accessed_in, scope: [:bibliographies, :list])} #{I18n.l(accessed_in, format: :bibliography)}" if accessed_in
      r.join(". ")
    when TYPE_FREE
      title
    end
  end

  def self.all_by_allocation_tags(allocation_tags_ids)
    joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: allocation_tags_ids}).uniq
  end

end
