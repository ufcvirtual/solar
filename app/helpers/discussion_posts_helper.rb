module DiscussionPostsHelper

  def list_portlet_discussion_posts(allocations)
    all_discussions = Discussion.all_by_allocations(allocations)

    return [] if all_discussions.empty? # sem discussions

    # lista de ids das discussions
    discussions_ids = []
    all_discussions.each do |discussion|
      discussions_ids << discussion.id
    end
    
    Post.recent_by_discussions(discussions_ids.join(','), Rails.application.config.items_per_page.to_i)
  end

  private

  # Verifica se a messagem foi postada hoje ou não!
  def posted_today?(message_datetime)
    message_datetime === Date.today
  end

  #retorna discussions onde o usuário pode interagir.
  def permitted_discussions(offer_id = nil, group_id = nil, discussion_id = nil)
    # uma discussion eh ligada a uma turma ou a uma oferta
    if !(group_id.nil? && offer_id.nil?)
      query_discussions = "SELECT distinct d.id as discussionid, d.name
                       FROM discussions d
                       LEFT JOIN allocation_tags at ON d.allocation_tag_id = at.id"
      unless (offer_id.nil? && group_id.nil?)
        query_discussions << " and ( "

        temp_query_discussions = []
        temp_query_discussions << " at.group_id in ( #{group_id} )" unless group_id.nil?
        temp_query_discussions << " at.offer_id in ( #{offer_id} )" unless offer_id.nil?
        temp_query_discussions << " at.group_id in ( select id from groups where offer_id = #{offer_id} ) "  unless offer_id.nil?

        query_discussions << temp_query_discussions.join(' OR ')

        query_discussions << "     ) "
      end

      #vê se passou discussion
      query_discussions += " and d.id=#{discussion_id} " unless discussion_id.nil?

      return Discussion.find_by_sql(query_discussions)
    end
  end

end
