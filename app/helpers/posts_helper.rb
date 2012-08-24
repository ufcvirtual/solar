module PostsHelper

  def post_html(post, display_mode = 'list', can_interact = false)
    user = post.user
    children = post.children
    editable = ((post.user_id == current_user.id) && (children.count == 0))

    child_html = ''
    children.each { |child| child_html << post_html(child, true, can_interact)} unless display_mode == 'list'

    html = <<HTML
      <table border="0" cellpadding="0" cellspacing="0" class="forum_post" id="#{post.id}">
        <tr>
          <td rowspan="3" class="forum_post_icon">
            #{image_tag(user.photo.url(:forum), :alt => t(:mysolar_alt_img_user) + ' ' + user.nick)}
          </td>
          <td class="forum_post_head">
            <div class="forum_post_author">
              <div class="forum_participant_nick" alt="#{user.nick}">
                #{user.nick}
              </div>
              <div class="forum_participant_profile" >
                #{(profile = post.profile).nil? ? '' : profile.name}
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
            #{buttons(post, editable, can_interact)}
            #{child_html}

          </td>
        </tr>
        <tr></tr>
      </table>
HTML
  end

  def attachments(post, editable = false, can_interact = false)
    files = post.files
    return '' if files.count == 0

    html, html_files =  '', ''
    files.each do |file|
      link_to_down = (link_to file.attachment_file_name, download_post_post_file_path(post, file))
      link_to_remove = (editable and can_interact) ? (link_to (image_tag "icon_delete_small.png", :alt => t(".remove_file")), 
        post_post_file_path(post, file), :confirm => t(".remove_file_confirm"), :method => :delete, :title => t(".remove_file"), 'data-tooltip' => t(".remove_file")) : ''
      html_files << '<li>'
      html_files <<     "#{link_to_down}&nbsp;&nbsp;#{link_to_remove}"
      html_files << '</li>'
    end

    html = <<HTML
      <div class="forum_post_attachment">
        <h3>
          #{t(".file_list")}
        </h3>
        <ul class="forum_post_attachment_list">
          #{html_files}
        </ul>
      </div>
HTML
  end

  def buttons(post, editable = false, can_interact = false)
    post_string = '<div class="forum_post_buttons">'

    if can_interact
      if editable
        post_string << "<button type='button' class='btn btn_default forum_button_attachment' onclick='showUploadForm(\"#{new_post_post_file_path(post)}\");'>"
        post_string <<    t(".attach_file") << (image_tag "icon_attachment.png", :alt => t(".attach_file"))
        post_string << "</button>"
        post_string << "<input type='button' onclick='delete_post(#{post.id}, \"#{discussion_post_path(post.discussion, post)}\")' class='btn btn_caution' value='#{t(".remove")}'/>"
        post_string << "<input type='button' onclick='javascript:update_post(this, #{post.id}, #{post.parent_id || 0})' class='btn btn_default update_post' value='#{t(".edit")}' />"
      end

      if post.can_be_answered?
        post_string << "<input type='button' level='#{post.level}' class='btn btn_default response_post' value='#{t(".answer")}' onclick='javascript:new_post(this, #{post.id})' />"
      end
    else
      post_string << "<a class='forum_post_link_disabled forum_post_link_remove_disabled'>#{t(".remove")}</a>&nbsp;&nbsp;"
      post_string << "<a class='forum_post_link_disabled'>#{t(".edit")}</a>&nbsp;&nbsp;"
      post_string << "<a class='forum_post_link_disabled'>#{t(".answer")}</a>"
    end

    post_string << '</div>'
  end

end
