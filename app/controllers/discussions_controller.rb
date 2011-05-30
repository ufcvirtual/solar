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
    @discussion = Discussion.find(discussion_id)
    @posts = return_discussion_posts(discussion_id, true)# método no helper. Quais variaveis?
  end

end





# # GET /discussions
# # GET /discussions.xml
# def index
# @discussions = Discussion.all
# 
# respond_to do |format|
# format.html # index.html.erb
# format.xml  { render :xml => @discussions }
# end
# end
# 
# # GET /discussions/1
# # GET /discussions/1.xml
# def show
# @discussion = Discussion.find(params[:id])
# 
# respond_to do |format|
# format.html # show.html.erb
# format.xml  { render :xml => @discussion }
# end
# end
# 
# # GET /discussions/new
# # GET /discussions/new.xml
# def new
# @discussion = Discussion.new
# 
# respond_to do |format|
# format.html # new.html.erb
# format.xml  { render :xml => @discussion }
# end
# end
# 
# # GET /discussions/1/edit
# def edit
# @discussion = Discussion.find(params[:id])
# end
# 
# # POST /discussions
# # POST /discussions.xml
# def create
# @discussion = Discussion.new(params[:discussion])
# 
# respond_to do |format|
# if @discussion.save
# format.html { redirect_to(@discussion, :notice => 'Discussion was successfully created.') }
# format.xml  { render :xml => @discussion, :status => :created, :location => @discussion }
# else
# format.html { render :action => "new" }
# format.xml  { render :xml => @discussion.errors, :status => :unprocessable_entity }
# end
# end
# end
# 
# # PUT /discussions/1
# # PUT /discussions/1.xml
# def update
# @discussion = Discussion.find(params[:id])
# 
# respond_to do |format|
# if @discussion.update_attributes(params[:discussion])
# format.html { redirect_to(@discussion, :notice => 'Discussion was successfully updated.') }
# format.xml  { head :ok }
# else
# format.html { render :action => "edit" }
# format.xml  { render :xml => @discussion.errors, :status => :unprocessable_entity }
# end
# end
# end
# 
# # DELETE /discussions/1
# # DELETE /discussions/1.xml
# def destroy
# @discussion = Discussion.find(params[:id])
# @discussion.destroy
# 
# respond_to do |format|
# format.html { redirect_to(discussions_url) }
# format.xml  { head :ok }
# end
# end
# end
