class ChangeMessagesAndLabels < ActiveRecord::Migration
  def up
    ml = MessageLabel.where(label_system: true)

    change_table :messages do |t|
      t.change :content, :text, null: false

      t.references :allocation_tag
      t.foreign_key :allocation_tags

      t.timestamps
    end

    # recuperando dados
    ml.each do |l|
      messages = l.messages

      messages.each do |m|
        m.allocation_tag_id = Group.where(code: l.title.split('|')[1]).first.try(:allocation_tag).try(:id)
        m.created_at = m.send_date
        m.save
      end

      l.destroy # destruindo label do sistema
    end

    change_table :messages do |t|
      t.remove :send_date
    end

    change_table :message_labels do |t|
      t.remove :label_system
      t.rename :title, :name
    end
  end

  def down
    change_table :messages do |t|
      t.remove :allocation_tag_id
      t.datetime :send_date
    end

    change_table :message_labels do |t|
      t.boolean :label_system, default: true
      t.rename :name, :title
    end
  end
end
