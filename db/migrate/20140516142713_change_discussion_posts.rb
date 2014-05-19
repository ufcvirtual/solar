class ChangeDiscussionPosts < ActiveRecord::Migration
  def up
    change_table :discussion_posts do |t|
      t.references :academic_allocation
      t.index :academic_allocation_id
    end

    Post.where(parent_id: nil).each do |post|
      # replicates post to each academic_allocation considering its children and files
      academic_allocations = AcademicAllocation.where(academic_tool_type: "Discussion", academic_tool_id: post.discussion_id)
      academic_allocations.each do |academic_allocation|
        if academic_allocation == academic_allocations.first
          post.update_attribute(:academic_allocation_id, academic_allocation.id)
          update_children(post, academic_allocation.id)
        else
          new_post = Post.new
          duplicate_post(post, new_post, academic_allocation.id)
        end
      end
    end

    # change_column :discussion_posts, :academic_allocation_id, :integer, null: false
    remove_column :discussion_posts, :discussion_id
  end

  def down
    change_table :discussion_posts do |t|
      t.references :discussion
      t.index :discussion_id
    end

    posts_by_discussion = Post.joins(:academic_allocation).where(academic_allocations: {academic_tool_type: "Discussion"}).select("discussion_posts.*, academic_allocations.academic_tool_id").group_by{|post| post.academic_tool_id}

    posts_by_discussion.each do |posts|
      discussion_id = posts[0]
      posts         = posts[1]
      
      posts.each do |post|
        # if already exists an equal post to the discussion
        if Post.where(post.attributes.except("id", "academic_allocation_id", "academic_tool_id", "updated_at", "created_at").merge("discussion_id" => discussion_id.to_i)).size > 0
          post.destroy
        else
          post.update_attribute(:discussion_id, discussion_id.to_i)
        end
      end
    end

    # change_column :discussion_posts, :discussion_id, :integer, null: false
    remove_column :discussion_posts, :academic_allocation_id
  end

  private

    def duplicate_post(post, new_post, academic_allocation_id, parent_id=nil)
      new_post.attributes = post.attributes.merge(academic_allocation_id: academic_allocation_id, parent_id: parent_id)
      new_post.save

      post.files.each do |file|
        new_post.files.create file.attributes
      end

      post.children.each do |child|
        new_child = new_post.children.new
        duplicate_post(child, new_child, academic_allocation_id, new_post.id)
      end
    end

    def update_children(post, academic_allocation_id)
      children = post.children
      unless children.empty?
        children.update_all(academic_allocation_id: academic_allocation_id)
        children.each do |child|
          update_children(child, academic_allocation_id)
        end
      end
    end

end
