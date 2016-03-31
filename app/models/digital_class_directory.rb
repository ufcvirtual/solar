class DigitalClassDirectory < ActiveRecord::Base
  belongs_to :related_taggable

  validates_uniqueness_of :directory_id, scope: :related_taggable_id

  validate :verify_taggable

  def verify_taggable
    errors.add(:related_taggable_id, 'so pode para turma') if related_taggable.group_id.nil?
    other_taggables = DigitalClassDirectory.where(directory_id: directory_id).map(&:related_taggable)
    errors.add(:related_taggable_id, 'so pode ser compartilhado entre turmas') if other_taggables.any? && other_taggables.first.offer_id != related_taggable.offer_id
  end

  def self.get_directories_by_allocation_tag(allocation_tag)
    column = "#{allocation_tag.refer_to}_id"
    DigitalClassDirectory.joins(:related_taggable).where(related_taggables: { column => allocation_tag.send(column) })
  end

  def self.get_directories_by_object(object)
    column = "#{object.class.tableize.singularize}_id"
    DigitalClassDirectory.joins(:related_taggable).where(related_taggables: { column => allocation_tag.send(column) })
  end

  def self.get_params_to_directory(directory_id)
    rts = DigitalClassDirectory.where(directory_id: directory_id).map(&:related_taggable)
    rt  = rts.first
    rt.info.merge!(tags: [rts.map(&:group).map(&:code), rt.semester.name, rt.curriculum_unit_type.description].flatten.uniq.join(','))
  end

  def self.get_params_to_directory_by_groups(groups_ids)
    rts = RelatedTaggable.where(group_id: groups_ids)
    rt  = rts.first
    rt.info.merge!(tags: [rts.map(&:group).map(&:code), rt.semester.name, rt.curriculum_unit_type.description].flatten.uniq.join(','))
  end

  def self.create_directory(groups_ids=[])
    name = "Diretório Solar" # definir nome padrao
    raise 'empty' if groups_ids.empty?

    ActiveRecord::Base.transaction do
      rts = RelatedTaggable.where(group_id: groups_ids)
      rt  = rts.first
      params = rt.info.merge!(tags: [rts.map(&:group).map(&:code), rt.semester.name, rt.curriculum_unit_type.description].flatten.uniq.join(',')) 
      directory = DigitalClass.call('directories', params.merge!({ name: name }))
      if directory.empty?
        directory = DigitalClass.call('directories', params.merge!({ name: name }), [], :post) 
        dir_id = directory['id'].to_i
        rts.each do |rt|
          DigitalClassDirectory.create related_taggable_id: rt.id, directory_id: dir_id
        end
      else
        dir_id = directory.first['id'].to_i
      end
      dir_id
    end
  end

end
