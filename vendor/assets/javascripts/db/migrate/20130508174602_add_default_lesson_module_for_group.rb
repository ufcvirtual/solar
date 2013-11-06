class AddDefaultLessonModuleForGroup < ActiveRecord::Migration
  def up
    change_table :lesson_modules do |t|
      t.boolean :is_default, default: false, null: false
    end

    Offer.all.each do |o|
      LessonModule.create(allocation_tag: o.allocation_tag, name: 'Geral', is_default: true) if o.allocation_tag
    end

    Group.all.each do |g|
      LessonModule.create(allocation_tag: g.allocation_tag, name: 'Geral da Turma', is_default: true) if g.allocation_tag
    end
  end

  def down
    remove_column :lesson_modules, :is_default
  end
end
