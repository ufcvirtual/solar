module PostsHelper

  def post_html(post, display_mode = 'list', can_interact = false)
    user     = post.user
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
            <div class="forum_post_wrapper">
              <div class="forum_post_inner_content">
              #{sanitize(post.content)}
              </div>
              #{attachments(post, editable, can_interact)}
              #{buttons(post, editable, can_interact)}
              <div class="forum_post_reply"></div>
            </div>
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
      link_to_down   = (link_to file.attachment_file_name, download_post_post_file_path(post, file))
      link_to_remove = (editable and can_interact) ? (link_to (content_tag(:i, nil, :class=>'icon-cross-3 warning')), 
        post_post_file_path(post, file), :confirm => t(".remove_file_confirm"), :method => :delete, :title => t(".remove_file"), 'data-tooltip' => t(".remove_file"), :class=>'nodecoration') : ''
      html_files << '<li>'
      html_files <<     "#{link_to_down}&nbsp;&nbsp;#{link_to_remove}"
      html_files <<     "<div class='audio' id='audio-#{file.id}' data-type='#{file.attachment_file_name.split(".").last}' data-source='#{download_post_post_file_url(post, file)}'></div>" if file.attachment_content_type.index('audio') or file.attachment_content_type.index('video')
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
    post_string << "<div class='btn-group'>"
    if can_interact
      if editable
        post_string << "<button type='button' class='btn forum_button_attachment' onclick='showUploadForm(\"#{new_post_post_file_path(post)}\");' data-tooltip='#{t(".attach_file")}' value='#{t(".attach_file")}'>"
        post_string << (content_tag(:i, nil, :class=>'icon-paperclip'))
        post_string << "</button>"
        post_string << "<button type='button' class='btn btn_caution' onclick='delete_post(#{post.id}, \"#{discussion_post_path(post.discussion, post)}\")' data-tooltip='#{t(".remove")}' value='#{t(".remove")}'>"
        post_string << (content_tag(:i, nil, :class=>'icon-trash'))
        post_string << "</button>"
        post_string << "<button type='button' class='btn update_post' onclick='javascript:update_post(this, #{post.id}, #{post.parent_id || 0})' data-tooltip='#{t(".edit")}' value='#{t(".edit")}'>"
        post_string << (content_tag(:i, nil, :class=>'icon-edit'))
        post_string << "</button>"
      end

      if post.can_be_answered?
        post_string << "<button type='button' level='#{post.level}' class='btn response_post' onclick='javascript:new_post(this, #{post.id})' data-tooltip='#{t(".answer")}' value='#{t(".answer")}'>"
        post_string << (content_tag(:i, nil, :class=>'icon-reply'))
        post_string << "</button>"
      end
    else
      post_string << "<button type='button' class='btn btn_disabled' data-tooltip='#{t(".remove")}' value='#{t(".remove")}' disabled='disabled'><i class='icon-trash'></i></button>"
      post_string << "<button type='button' class='btn btn_disabled' data-tooltip='#{t(".edit")}' value='#{t(".edit")}' disabled='disabled'><i class='icon-edit'></i></button>"
      post_string << "<button type='button' class='btn btn_disabled' data-tooltip='#{t(".answer")}' value='#{t(".answer")}' disabled='disabled'><i class='icon-reply'></i></button>"
    end
    post_string << "</div>"
    post_string << '</div>'
  end

end
