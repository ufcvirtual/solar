class Bibliography < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION, CURRICULUM_UNIT_PERMISSION = true, true, true

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  attr_accessible :type_bibliography, :title, :subtitle, :address, :publisher, :pages, :count_pages, :volume, :edition, :publication_year,
    :periodicity, :issn, :isbn, :periodicity_year_start, :periodicity_year_end, :article_periodicity_title,
    :fascicle, :publication_month, :additional_information, :url, :accessed_in

  validates :title, :type_bibliography, presence: true
  validates :issn, length: {is: 9}, if: "issn.present?" # com formatacao
  validates :isbn, length: {is: 17}, if: "isbn.present?" # com formatacao

  validates :address, :publisher, :edition, :publication_year                 , presence: true, if: "type_bibliography == #{Bibliography_Book}"
  validates :address, :publisher, :periodicity_year_start                     , presence: true, if: "type_bibliography == #{Bibliography_Periodical}"
  validates :address, :volume, :pages, :publication_year, :publication_month  , presence: true, if: "type_bibliography == #{Bibliography_Article}"
  validates :url, :accessed_in                                                , presence: true, if: "type_bibliography == #{Bibliography_Eletronic_Doc}"

  # TODO
    # resume
    # retornar o nome do tipo ## type_name?

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

  # ainda nao terminado
  def resume
    btype = case type_bibliography
    when Bibliography_Book
    when Bibliography_Periodical
      "#{title}. #{address}: #{publisher}. #{periodicity_year_start} - #{periodicity_year_end}. #{periodicity}. ISSN #{issn}"
    when Bibliography_Article
    when Bibliography_Eletronic_Doc
    when Bibliography_Free
      title
    end
  end

  def self.all_by_allocation_tags(allocation_tags_ids)
    joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: allocation_tags_ids})
  end

end
