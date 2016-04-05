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
    DigitalClassDirectory.joins(:related_taggable).where(related_taggables: { column => allocation_tag.send(column) }).uniq
  end

  def self.get_directories_by_object(object)
    column = "#{object.class.to_s.tableize.singularize}_id"
    DigitalClassDirectory.joins(:related_taggable).where(related_taggables: { column => object.id }).uniq
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

  def self.get_directories_by_related_taggables(rts)
    rts = rts.map(&:id)
    DigitalClassDirectory.find_by_sql <<-SQL
      SELECT DISTINCT dcd1.directory_id, dcd2.count
      FROM digital_class_directories dcd1
      JOIN (
        SELECT DISTINCT dcd.directory_id, COUNT(dcd.directory_id) AS count
        FROM digital_class_directories dcd
        WHERE related_taggable_id IN (#{rts.join(',')})
        GROUP BY dcd.directory_id
      ) dcd2 ON dcd2.directory_id = dcd1.directory_id
      WHERE dcd2.count = #{rts.count};
    SQL
  end

  def self.create_directory(groups_ids=[])
    name = "Diretório Solar" # definir nome padrao
    raise 'empty' if groups_ids.empty?

    ActiveRecord::Base.transaction do
      rts = RelatedTaggable.where(group_id: groups_ids)
      raise 'diff' if rts.map(&:offer_id).uniq.size > 1
      directories = DigitalClassDirectory.get_directories_by_related_taggables(rts)
      if directories.empty?
        rt  = rts.first
        params = rt.info.merge!(tags: [rts.map(&:group).map(&:code), rt.semester.name, rt.curriculum_unit_type.description].flatten.uniq.join(',')) 
        directory = DigitalClass.call('directories', params.merge!({ name: name }), [], :post) 
        dir_id = directory['id'].to_i
        rts.each do |rt|
          DigitalClassDirectory.create related_taggable_id: rt.id, directory_id: dir_id
        end
      else
        dir_id = directories.first['directory_id'].to_i
      end
      dir_id
    end
  end

end
