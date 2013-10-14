class Bibliography < ActiveRecord::Base

  GROUP_PERMISSION, OFFER_PERMISSION, CURRICULUM_UNIT_PERMISSION = true, true, true

  has_many :academic_allocations, as: :academic_tool, dependent: :destroy
  has_many :allocation_tags, through: :academic_allocations
  has_many :groups, through: :allocation_tags

  attr_accessible :type_bibliography, :title, :subtitle, :address, :publisher, :pages, :volume, :edition, :publication_year,
    :periodicity, :issn, :isbn, :periodicity_year_start, :periodicity_year_end, :article_periodicity_title,
    :fascicle, :publication_month, :additional_information, :url, :accessed_in

  # constantes :: tipos de bibliografia
    # 1 - livro
    # 2 - periodico
    # 3 - artigo
    # 4 - documento eletronico
    # 5 - livre

  validates :title, :type_bibliography, presence: true
  validates :issn, length: {is: 8}, if: "not issn.nil?"
  validates :isbn, length: {is: 13}, if: "not isbn.nil?"

  def self.all_by_allocation_tags(allocation_tags_ids)
    joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: allocation_tags_ids})
  end

end
