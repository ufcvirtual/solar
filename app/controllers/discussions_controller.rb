class DiscussionsController < ApplicationController

  include DiscussionPostsHelper

  #load_and_authorize_resource #Setar permissoes!!!!!
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
    discussion_id = params[:id]
    @display_mode = params[:display_mode]
    
    @discussion = Discussion.find(discussion_id)
    if @display_mode == "PLAINLIST"
      @posts = return_discussion_posts(discussion_id, true)
    else
      @posts = return_discussion_posts(discussion_id, false)
    end
  end

  def new_post
    discussion_id = params[:discussion_id]
    #DEFINIR O PROFILE!!!! ###################################################
    profile_id = 2
    content = params[:content]
    father_id = params[:parent_post_id]
    @display_mode = params[:display_mode]

    new_discussion_post = DiscussionPost.new :discussion_id => discussion_id, :user_id => current_user.id, :profile_id => profile_id, :content => content, :father_id => father_id
    new_discussion_post.save

    @discussion = Discussion.find(discussion_id)
    if @display_mode == "PLAINLIST"
      @posts = return_discussion_posts(discussion_id, true)
    else
      @posts = return_discussion_posts(discussion_id, false)
    end
    render "show"
  end

  def remove_post
    discussion_id = params[:discussion_id]
    discussion_post_id = params[:discussion_post_id]
    @display_mode = params[:display_mode]

    DiscussionPost.delete(discussion_post_id)#.delete()

    @discussion = Discussion.find(discussion_id)
    if @display_mode == "PLAINLIST"
      @posts = return_discussion_posts(discussion_id, true)
    else
      @posts = return_discussion_posts(discussion_id, false)
    end
    render "show"
  end

  def update_post
    discussion_id = params[:discussion_id]
    discussion_post_id = params[:discussion_post_id]
    new_content = params[:content]
    @display_mode = params[:display_mode]

    @discussion = Discussion.find(discussion_id)
    post = DiscussionPost.find(discussion_post_id);

    post.update_attributes({:content => new_content})

    if @display_mode == "PLAINLIST"
      @posts = return_discussion_posts(discussion_id, true)
    else
      @posts = return_discussion_posts(discussion_id, false)
    end
    render "show"
  end
end