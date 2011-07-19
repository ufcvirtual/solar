class DiscussionsController < ApplicationController

  include DiscussionPostsHelper

  load_and_authorize_resource #Setar permissoes!!!!!

  def list

    # pegando dados da sessao e nao da url
    group_id = session[:opened_tabs][session[:active_tab]]["group_id"]
    offer_id = session[:opened_tabs][session[:active_tab]]["offer_id"]

    if group_id.nil?
      group_id = -1
    end
    
    if offer_id.nil?
      offer_id = -1
    end

    # retorna os fóruns da turma
    # at.id as id, at.offer_id as offerid,l.allocation_tag_id as alloctagid,l.type_lesson, privacy,description,
    query = "SELECT * 
              FROM 
                (SELECT d.name, d.id, d.start, d.end, d.description 
                 FROM discussions d 
                 INNER JOIN allocation_tags t on d.allocation_tag_id = t.id
                 INNER JOIN groups g on g.id = t.group_id
                 WHERE g.id = #{group_id}
              
                 UNION ALL
              
                 SELECT d.name, d.id, d.start, d.end, d.description 
                 FROM discussions d 
                 INNER JOIN allocation_tags t on d.allocation_tag_id = t.id
                 INNER JOIN offers o on o.id = t.offer_id
                 WHERE o.id = #{offer_id}
                ) as available_discussions
              ORDER BY start;"

    @discussions = Discussion.find_by_sql(query)

  end

  def show
    load_posts 
  end

  def new_post
    discussion_id = params[:discussion_id]
    content       = params[:content]
    parent_id     = params[:parent_post_id]
    
    #DEFINIR O PROFILE!!!! 
    #profile_id    = 2
    profile_id    = 1

    new_discussion_post = DiscussionPost.new :discussion_id => discussion_id, :user_id => current_user.id, :profile_id => profile_id, :content => content, :father_id => parent_id
    new_discussion_post.save

    if @display_mode != "PLAINLIST"
      hold_pagination
    end
    redirect_to "/discussions/show/" << discussion_id
  end

  def remove_post
    discussion_id = params[:discussion_id]
    discussion_post_id = params[:discussion_post_id]
    DiscussionPost.delete(discussion_post_id)

    hold_pagination
    redirect_to "/discussions/show/" << discussion_id
  end

  def update_post
    discussion_id = params[:discussion_id]
    discussion_post_id = params[:discussion_post_id]
    new_content = params[:content]

    post = DiscussionPost.find(discussion_post_id);
    post.update_attributes({:content => new_content})

    hold_pagination
    redirect_to "/discussions/show/" << discussion_id
  end

  private
  def load_posts
    discussion_id = params[:discussion_id]
    discussion_id = params[:id] if discussion_id.nil?

    @display_mode = params[:display_mode]

    if @display_mode.nil?
      @display_mode = session[:forum_display_mode]
    else
      session[:forum_display_mode] = @display_mode
    end

    @discussion = Discussion.find(discussion_id)
    if @display_mode == "PLAINLIST"
      @posts = return_discussion_posts(@discussion.id, true)
    else
      @posts = return_discussion_posts(@discussion.id, false)
    end
  end
end
