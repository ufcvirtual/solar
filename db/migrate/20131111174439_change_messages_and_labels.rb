class ChangeMessagesAndLabels < ActiveRecord::Migration
  def up
    ml = MessageLabel.where(label_system: true)

    change_table :messages do |t|
      t.change :content, :text, null: false

      t.references :allocation_tag

      t.timestamps
    end
    add_foreign_key :messages, :allocation_tags
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

    ## msgs que nao tem label
    msgs = Message.where("created_at IS NULL AND send_date IS NOT NULL")
    msgs.each do |m|
      m.created_at = m.send_date
      m.save
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
