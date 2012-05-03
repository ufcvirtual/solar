module PostsHelper

  def post_html(post, display_mode='list', can_interact=false)
    user = User.find(post.user_id)
    photo_url = user.photo.url(:forum)

    childs = post.children
    editable = ((post.user.id == current_user.id) && (childs.count == 0))

    child_html = ''
    childs.each { |child| child_html << post_html(child, true, can_interact)} unless display_mode == 'list'

    html = <<HTML
      <table border="0" cellpadding="0" cellspacing="0" class="forum_post">
        <tr>
          <td rowspan="3" class="forum_post_icon">
            #{image_tag(photo_url, :alt => t(:mysolar_alt_img_user) + ' ' + user.nick)}
          </td>
          <td class="forum_post_head">
            <div class="forum_post_author">
              <div class="forum_participant_nick" alt="#{user.nick}">
                #{user.nick}
              </div>
            </div>
            <div class="forum_post_date">
              #{l(post.updated_at.to_time, :format => :discussion_post_date)}<br />#{l(post.updated_at.to_time, :format => :discussion_post_hour)}
            </div>
          </td>
        </tr>
        <tr>
          <td class="forum_post_content" colspan="2">
            <div class="forum_post_inner_content">
              #{sanitize(post.content)}
            </div>

            #{attachments(post, editable, can_interact)}
            #{buttons(post, editable,can_interact)}
            #{child_html}

          </td>
        </tr>
        <tr></tr>
      </table>
HTML

  end

  def attachments(post, editable = false, can_interact = false)
    html =  ''

    files = post.discussion_post_files

    unless files.count == 0
      html <<   '<div class="forum_post_attachment">'
      html <<   '<h3>' << t(:forum_file_list) << '</h3>'

      html <<     '<ul class="forum_post_attachment_list">'
      files.each do |file|
        html <<    '<li>'
        html <<      '<a href="#">'<<(link_to file.attachment_file_name, :controller => "discussions", :action => "download_post_file", :idFile => file.id, :id => @discussion.id)<<'</a>&nbsp;&nbsp;'
        html <<   (link_to (image_tag "icon_delete_small.png", :alt => t(:forum_remove_file)), {:controller => "discussions", :action => "remove_attached_file", :idFile => file.id, :current_page => @current_page, :id => @discussion.id}, :confirm=>t(:forum_remove_file_confirm), :title => t(:forum_remove_file), 'data-tooltip' => t(:forum_remove_file)) if editable && can_interact
        html <<    '</li>'
      end
      html <<     '</ul>'
      html <<   '</div>'
    end

    return html
  end

  def buttons(post, editable = false, can_interact = false)
    post_string = '<div class="forum_post_buttons">'

    if can_interact
      if editable
        post_string << '<button type="button" class="btn btn_default forum_button_attachment" onclick="showUploadForm(\''<< post[:discussion_id].to_s << '\',\'' << post[:id].to_s << '\');">'<< t(:forum_attach_file) << (image_tag "icon_attachment.png", :alt => t(:forum_attach_file)) << '</button>' if editable and can_interact
        post_string << '<input type="button" onclick="removePost(' << post[:id].to_s << ')" class="btn btn_caution" value="' << t(:forum_show_remove) << '"/>'
        post_string << '<input type="button" onclick="setDiscussionPostId(' << post[:id].to_s << ')" class="btn btn_default updateDialogLink" value="' << t(:forum_show_edit) << '"/>'
      end
      if post.can_be_answered?
        post_string << '<input type="button" onclick="setParentPostId(' << post[:id].to_s << '); setParentPostLevel(' << post[:level].to_s << ');" class="btn btn_default postDialogLink" value="' << t(:forum_show_answer) << '" />'      
      end
    else
      post_string <<      '    <a class="forum_post_link_disabled forum_post_link_remove_disabled">' << t('forum_show_remove') << '</a>&nbsp;&nbsp;
                               <a class="forum_post_link_disabled">' << t('forum_show_edit') << '</a>&nbsp;&nbsp;
                               <a class="forum_post_link_disabled">' << t('forum_show_answer') << '</a>'
    end  
   
    post_string <<      '</div></div>'

    return post_string
  end

end
