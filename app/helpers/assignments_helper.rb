module AssignmentsHelper

  include Bbb

  ## recupera o icone correspondente ao tipo de arquivo
  def icon_attachment(file)
    case File.extname(file)
      when '.pdf'
        'mimetypes/pdf.png'
      when '.doc', '.docx', '.odt', '.fodt'
        'mimetypes/document.png'
      when '.xls', '.xlsx', '.ods', '.fods'
        'mimetypes/spreadsheet.png'
      when '.ppt', '.pptx', '.odp', '.fodp'
        'mimetypes/presentation.png'
      when '.odf', '.tex'
        'mimetypes/formula.png'
      when '.txt'
        'mimetypes/text.png'
      when '.rtf'
        'mimetypes/rtf.png'
      when '.link', '.html', '.htm'
        'mimetypes/url.png'
      when '.css'
        'mimetypes/css.png'
      when '.png', '.jpg', '.jpeg', '.bmp', '.xcf'
        'mimetypes/image.png'
      when '.mp3', '.wav', '.m4a', '.wav', '.aac'
        'mimetypes/audio.png'
      when '.avi', '.mpg', '.mp4'
        'mimetypes/video.png'
      when '.zip', '.7z', '.rar', '.ace'
        'mimetypes/zip.png'
      when '.fla', '.swf'
        'mimetypes/flash.png'
      when '.svg', '.ai', '.odg', '.fodg'
        'mimetypes/vector.png'
      when '.sla', '.scd'
        'mimetypes/scribus.png'
      else
        'mimetypes/default.png'
    end
  end

  def get_ac
    @ac = AcademicAllocation.where(academic_tool_type: 'Assignment', academic_tool_id: (params[:assignment_id] || params[:id]), allocation_tag_id: active_tab[:url][:allocation_tag_id]).first
  end

  def verify_owner!(aparams)
    owner(aparams)
    raise CanCan::AccessDenied unless @own_assignment
  end

  def verify_owner_or_responsible!(allocation_tag_id = nil, academic_allocation_user = nil)
    @student_id, @group_id = (params[:group_id].nil? ? [params[:student_id], nil] : [nil, params[:group_id]])
    @group = GroupAssignment.find(params[:group_id]) unless @group_id.nil?
    @own_assignment = Assignment.owned_by_user?(current_user.id, { student_id: @student_id, group: @group, academic_allocation_user: academic_allocation_user })
    redirect_to list_assignments_path, alert: t('exams.restrict') if @group.blank? && (academic_allocation_user.try(:assignment) || Assignment.find(params[:id])).type_assignment == Assignment_Type_Group
    raise CanCan::AccessDenied unless (@own_assignment || AllocationTag.find(allocation_tag_id).is_observer_or_responsible?(current_user.id)) && (@student_id.nil? && academic_allocation_user.try(:user_id).nil? ? true : User.find(@student_id || academic_allocation_user.user_id).has_profile_type_at(allocation_tag_id))
  end

  def owner(aparams)
    acu_id = (aparams[:academic_allocation_user_id] || aparams.academic_allocation_user_id)
    raise CanCan::AccessDenied if acu_id.blank?
    acu = AcademicAllocationUser.find(acu_id)
    if acu.assignment.type_assignment == Assignment_Type_Group && @group.blank?
      @group = acu.group_assignment
      redirect_to list_assignments_path, alert: t('exams.restrict') if @group.blank?
    end
    @own_assignment = Assignment.owned_by_user?(current_user.id,  { student_id: @student_id, group: @group, academic_allocation_user: acu })
    #@bbb_online = bbb_online?
    @in_time    = acu.assignment.in_time?
  end

   def link_to_add_fields_ip(name, f, association, html_options={})
    new_object = f.object.class.reflect_on_association(association).klass.new

    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render("assignments/" + association.to_s.singularize + "_fields", :f => builder)
    end

    link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", html_options)
  end

  def link_to_remove_fields(name, f, html_options={})
    link_to_function(name, "remove_fields(this)", html_options)
  end

end
