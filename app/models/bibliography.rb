class Bibliography < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION, CURRICULUM_UNIT_PERMISSION = true, true, true

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags
  has_many :authors, dependent: :destroy

  accepts_nested_attributes_for :authors, allow_destroy: true

  validates :title, :type_bibliography, presence: true
  validates :issn, length: {is: 9}, if: "issn.present?" # com formatacao
  validates :isbn, length: {is: 17}, if: "isbn.present?" # com formatacao

  validates :address, :publisher, :edition, :publication_year                 , presence: true, if: "type_bibliography == #{Bibliography_Book}"
  validates :address, :publisher, :periodicity_year_start                     , presence: true, if: "type_bibliography == #{Bibliography_Periodical}"
  validates :address, :volume, :pages, :publication_year, :publication_month  , presence: true, if: "type_bibliography == #{Bibliography_Article}"
  validates :url, :accessed_in                                                , presence: true, if: "type_bibliography == #{Bibliography_Eletronic_Doc}"

  attr_accessible :type_bibliography, :title, :subtitle, :address, :publisher, :pages, :count_pages, :volume, :edition, :publication_year,
    :periodicity, :issn, :isbn, :periodicity_year_start, :periodicity_year_end, :article_periodicity_title,
    :fascicle, :publication_month, :additional_information, :url, :accessed_in,
    :authors_attributes

  def type
    btype = case type_bibliography
    when Bibliography_Book
      "book"
    when Bibliography_Periodical
      "periodical"
    when Bibliography_Article
      "article"
    when Bibliography_Eletronic_Doc
      "eletronic_doc"
    when Bibliography_Free
      "free"
    end

    I18n.t(btype, scope: [:bibliographies, :type]) if btype
  end

  def resume_authors
    authors.map(&:name).join(", ")
  end

  def resume
    btype = case type_bibliography
    when Bibliography_Book
      r = [resume_authors]
      r << title if title
      r << subtitle if subtitle
      r << "#{edition}. ed" if edition
      r << "#{address}: #{publisher}, #{publication_year}" if address and publisher and publication_year
      r << "#{count_pages} p" if count_pages
      r << "v. #{volume}" if volume
      r.join(". ")
    when Bibliography_Periodical
      r = [title]
      r << subtitle if subtitle
      r << "#{address}: #{publisher}" if address and publisher
      r << periodicity_year_end ? "#{periodicity_year_start} - #{periodicity_year_end}" : periodicity_year_start
      r << periodicity if periodicity
      r << "ISSN: #{issn}" if issn
      r.join(". ")
    when Bibliography_Article
      r = [resume_authors]
      r << title if title
      r << subtitle if subtitle
      r << article_periodicity_title if article_periodicity_title
      r << address if address
      r << "v. #{volume}" if volume
      r << "n. #{fascicle}" if fascicle
      r << "p. #{pages}, #{publication_month}, #{publication_year}" if pages and publication_month and publication_year
      r.join(". ")
    when Bibliography_Eletronic_Doc
      r = [resume_authors]
      r << title if title
      r << additional_information if additional_information
      r << "#{I18n.t(:available_in, scope: [:bibliographies, :list])} #{url}" if url
      r << "#{I18n.t(:accessed_in, scope: [:bibliographies, :list])} #{I18n.l(accessed_in, format: :bibliography)}" if accessed_in
      r.join(". ")
    when Bibliography_Free
      title
    end
  end

  def self.all_by_allocation_tags(allocation_tags_ids)
    joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: allocation_tags_ids})
  end

end
