module ReportsHelper

  $period_index = 1
  $max_tuples = 0
  $models = Array.new
  $models_info = Array.new
  $options_array = Array.new(10)
  $summary_array = Array.new(7)

  def self.query(query_type, period, type)
    case query_type
      when '1'
        reset_arrays #clean precausion..
        $options_array[0] = 430
        $options_array[1] = $options_array[2] = 0
        $options_array[3] = I18n.t('reports.commun_texts.info')
        $options_array[4] = I18n.t('reports.commun_texts.count')
        $options_array[9] = "#"
       
        models_info = Array.new(8)
        summary_array = Array.new(8)

        #(0..6).each do | index | models_info[index] = " " end
        summary_array[0] = I18n.t('reports.summary.courses_number')
        summary_array[1] = I18n.t('reports.summary.users_number')
        summary_array[2] = I18n.t('reports.summary.users_number_active')
        summary_array[3] = I18n.t('reports.summary.users_number_module_bound')
        summary_array[4] = I18n.t('reports.summary.users_number_module_unbound')
        summary_array[5] = I18n.t('reports.summary.number_of_students')
        summary_array[6] = I18n.t('reports.summary.disciplines_amount')
        summary_array[7] = I18n.t('reports.summary.files_portifolio')
        

        #INFO QUERIES
        #quantidade de cursos
        models_info[0] = "#{Course.count}"
        #quantidade de usuarios
        models_info[1] = "#{User.count}"
        #quantidade de usuarios ativos
        models_info[2] = "#{User.where(:active => TRUE).count}"

        # 3 user com o campo integrado com o valor true, e que o cpf não consta na tabela user_blacklist
        @user_blacklist = UserBlacklist.all
        models_info[3] = User.count(:all, :conditions => ['integrated = TRUE and cpf NOT IN (?)', @user_blacklist.map(&:cpf)])
        # 4 user não vinculado ao modulo academico
        models_info[4] = User.count(:all, :conditions => ['integrated = FALSE or integrated = TRUE and cpf IN (?)', @user_blacklist.map(&:cpf)])

        #quantidade de Disciplinas
        models_info[6] = "#{CurriculumUnit.count}"

        #passando de allocation_tags direto para offers....
        #portifólio: assignment_files -> sent_assignments -> academic_allocations -> allocation_tags -> offers -> semesters
        models_info[7] = AssignmentFile.joins("LEFT JOIN academic_allocations ON assignment_files.academic_allocation_user_id = academic_allocations.id")
        .joins("LEFT JOIN allocation_tags ON academic_allocations.allocation_tag_id = allocation_tags.id")
        .joins("LEFT JOIN offers ON allocation_tags.offer_id = offers.id")
        .joins("LEFT JOIN semesters ON offers.semester_id = semesters.id")
        .where("semesters.id = #{period} ").count #mudando o id do semestre.

        #passando por groups
        models_info[7] += AssignmentFile.joins("LEFT JOIN academic_allocations ON assignment_files.academic_allocation_user_id = academic_allocations.id")
        .joins("LEFT JOIN allocation_tags ON academic_allocations.allocation_tag_id = allocation_tags.id")
        .joins("LEFT JOIN groups ON allocation_tags.group_id = groups.id")
        .joins("LEFT JOIN offers ON groups.offer_id = offers.id")
        .joins("LEFT JOIN semesters ON offers.semester_id = semesters.id")
        .where("semesters.id = #{period} ").count #mudando o id do semestre.

        #quantidade de alunos alocados no ambiente
        t_users = Profile.joins("LEFT JOIN allocations ON allocations.profile_id = profiles.id")
        .where("cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND allocations.status= 1")
        .select(" COUNT(DISTINCT user_id) as t").first
        models_info[5] = t_users.t

        list = []
        index = 0
        summary_array.each do |model|  
          list << Report.new(model, models_info[index])
          index = index + 1
        end
        return list  
      when '2'
        puts Profile_Type_Student
        # query numero de alunos por curso
        reset_arrays #clean precausion..
        $options_array[0] = 430
        $options_array[1] = $options_array[2] = 0
        $options_array[3] = I18n.t('reports.commun_texts.name_course')
        $options_array[4] = I18n.t('reports.commun_texts.number_students')
        $options_array[9] = "#"

        if type=='courses'
          selectd = "concat(courses1.name, courses2.name, courses3.name) as name_model, COUNT(DISTINCT user_id) AS total" 
          $options_array[3] = I18n.t('reports.commun_texts.name_course')
        elsif type=='curriculum_units'  
          selectd = "concat(c1.name,c2.name, c3.name) as name_model, COUNT(DISTINCT user_id) AS total"
          $options_array[3] = I18n.t('reports.commun_texts.name_disciplines')
        elsif type=='groups'    
          selectd = "concat(concat(courses1.name, courses2.name, courses3.name), ' - ', concat(c1.name,c2.name, c3.name), ' - ', concat(groups.code,gr1.code)) as name_model, COUNT(DISTINCT user_id) AS total"
          $options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')+' - '+I18n.t('reports.commun_texts.name_groups')
        else  
          selectd = "concat(concat(courses1.name, courses2.name, courses3.name), ' - ', concat(c1.name,c2.name, c3.name)) as name_model, COUNT(DISTINCT user_id) AS total"
          $options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')
        end  
        models_info = Profile.joins("LEFT JOIN allocations ON allocations.profile_id = profiles.id AND cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND allocations.status= 1")
                            .joins("LEFT JOIN allocation_tags ON allocations.allocation_tag_id = allocation_tags.id")
                            .joins("LEFT JOIN offers of1 ON of1.id = allocation_tags.offer_id")
                            .joins("LEFT JOIN related_taggables rt ON rt.offer_id = of1.id")
                            .joins("LEFT JOIN groups gr1 ON gr1.id = rt.group_id AND gr1.status = TRUE")
                            .joins("LEFT JOIN courses courses1 ON courses1.id = of1.course_id")
                            .joins("LEFT JOIN curriculum_units c1 ON c1.id = of1.curriculum_unit_id")
                            .joins("LEFT JOIN groups ON groups.id = allocation_tags.group_id  AND groups.status = TRUE")
                            .joins("LEFT JOIN offers of2 ON groups.offer_id = of2.id")
                            .joins("LEFT JOIN courses courses2 ON of2.course_id = courses2.id")
                            .joins("LEFT JOIN curriculum_units c2 ON of2.curriculum_unit_id = c2.id")
                            .joins("LEFT JOIN courses courses3 ON courses3.id = allocation_tags.course_id")
                            .joins("LEFT JOIN curriculum_units c3 ON c3.id = allocation_tags.curriculum_unit_id")
                            .where("of1.semester_id=#{period} or of2.semester_id=#{period}")
                            .select(selectd) 
                            .group("name_model")
                            .order("name_model")        

      when '3'
        $options_array[0] = 430
        $options_array[1] = $options_array[2] = 0
        $options_array[3] = I18n.t('reports.commun_texts.name_course')
        $options_array[4] = I18n.t('reports.commun_texts.number_disciplines')
        $options_array[9] = "#"

        models_info = Course.joins("courses LEFT JOIN related_taggables ON courses.id = related_taggables.course_id AND semester_id= #{period}")
                            .select("courses.name AS name_model, COUNT(DISTINCT curriculum_unit_id) AS total")
                            .group("name_model")
                            .order("name_model") 

      when '4' 

        reset_arrays #clean precausion..

        $options_array[0] = 430
        $options_array[1] = $options_array[2] = 0
        $options_array[3] = I18n.t('reports.commun_texts.name_disciplines')
        $options_array[4] = I18n.t('reports.commun_texts.count')
        $options_array[9] = "#" #sempre o último todos os documentos tem

        if type=='courses'
          selectd = "concat(courses1.name, courses2.name, courses3.name) as name_model, COUNT(DISTINCT user_id) AS total" 
          $options_array[3] = I18n.t('reports.commun_texts.name_course')
        elsif type=='curriculum_units'  
          selectd = "concat(c1.name,c2.name, c3.name) as name_model, COUNT(DISTINCT user_id) AS total"
          $options_array[3] = I18n.t('reports.commun_texts.name_disciplines')
        elsif type=='groups'    
          selectd = "concat(concat(courses1.name, courses2.name, courses3.name), ' - ', concat(c1.name,c2.name, c3.name), ' - ', concat(groups.code,gr1.code)) as name_model, COUNT(DISTINCT user_id) AS total"
          $options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')+' - '+I18n.t('reports.commun_texts.name_groups')
        else  
          selectd = "concat(concat(courses1.name, courses2.name, courses3.name), ' - ', concat(c1.name,c2.name, c3.name)) as name_model, COUNT(DISTINCT user_id) AS total"
          $options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')
        end  
        models_info = Profile.joins("LEFT JOIN allocations ON allocations.profile_id = profiles.id AND cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean ) AND allocations.status= 1")
                            .joins("LEFT JOIN allocation_tags ON allocations.allocation_tag_id = allocation_tags.id")
                            .joins("LEFT JOIN offers of1 ON of1.id = allocation_tags.offer_id")
                            .joins("LEFT JOIN related_taggables rt ON rt.offer_id = of1.id")
                            .joins("LEFT JOIN groups gr1 ON gr1.id = rt.group_id AND gr1.status = TRUE")
                            .joins("LEFT JOIN courses courses1 ON courses1.id = of1.course_id")
                            .joins("LEFT JOIN curriculum_units c1 ON c1.id = of1.curriculum_unit_id")
                            .joins("LEFT JOIN groups ON groups.id = allocation_tags.group_id  AND groups.status = TRUE")
                            .joins("LEFT JOIN offers of2 ON groups.offer_id = of2.id")
                            .joins("LEFT JOIN courses courses2 ON of2.course_id = courses2.id")
                            .joins("LEFT JOIN curriculum_units c2 ON of2.curriculum_unit_id = c2.id")
                            .joins("LEFT JOIN courses courses3 ON courses3.id = allocation_tags.course_id")
                            .joins("LEFT JOIN curriculum_units c3 ON c3.id = allocation_tags.curriculum_unit_id")
                            .where("of1.semester_id=#{period} or of2.semester_id=#{period}")
                            .select(selectd) 
                            .group("name_model")
                            .order("name_model")      

      when '5'

        reset_arrays #clean precausion..
        $options_array[0] = 430
        $options_array[1] = $options_array[2] = 0
        #$options_array[3] = I18n.t('reports.commun_texts.name_forum')
        $options_array[4] = I18n.t('reports.commun_texts.count')
        $options_array[9] = "#" #sempre o último todos os documentos tem

        if type=='courses'
          selectd = "CONCAT(courses.name, ' - ', discussions.name) AS name_model, COUNT(DISTINCT discussion_posts) AS total" 
          $options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+ I18n.t('reports.commun_texts.name_forum')
        elsif type=='curriculum_units'  
          selectd = "CONCAT(curriculum_units.name, ' - ', discussions.name) AS name_model, COUNT(DISTINCT discussion_posts) AS total"
          $options_array[3] = I18n.t('reports.commun_texts.name_disciplines')+' - '+ I18n.t('reports.commun_texts.name_forum')
        elsif type=='groups'    
          selectd = "CONCAT(courses.name, ' - ', curriculum_units.name, ' - ',  groups.code, ' - ',  discussions.name )AS name_model, count(DISTINCT discussion_posts.id) AS total"
          $options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')+' - '+I18n.t('reports.commun_texts.name_groups')+' - '+ I18n.t('reports.commun_texts.name_forum')
        else  
          selectd = "CONCAT(courses.name, ' - ', curriculum_units.name, ' - ',  discussions.name ) AS name_model, count(DISTINCT discussion_posts.id) AS total"
          $options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')+' - '+ I18n.t('reports.commun_texts.name_forum')
        end  

        models_info = Discussion.joins("LEFT JOIN academic_allocations ON discussions.id = academic_allocations.academic_tool_id AND academic_tool_type='Discussion'")
                            .joins("LEFT JOIN discussion_posts ON academic_allocations.id = discussion_posts.academic_allocation_id")
                            .joins("LEFT JOIN allocation_tags ON allocation_tags.id = academic_allocations.allocation_tag_id")
                            .joins("LEFT JOIN related_taggables rt1 ON rt1.group_id = allocation_tags.group_id OR rt1.offer_id = allocation_tags.offer_id OR rt1.course_id = allocation_tags.course_id OR rt1.curriculum_unit_id = allocation_tags.curriculum_unit_id")
                            .joins("LEFT JOIN courses ON courses.id = rt1.course_id")
                            .joins("LEFT JOIN curriculum_units ON curriculum_units.id = rt1.curriculum_unit_id")
                            .joins("LEFT JOIN groups ON groups.id = rt1.group_id")                          
                            .where("rt1.semester_id=#{period}")
                            .select(selectd) 
                            .group("name_model")
                            .order("name_model")      
       

      end 
    end

  def self.reset_arrays
    (0..9).each do |index| $options_array[index]=" " end
    $options_array.clear
  end

  def self.get_options_array
    $options_array
  end

  def self.get_timestamp_pattern
    time = Time.now
      I18n.t('reports.commun_texts.timestamp_info')+" "+time.strftime(I18n.t('time.formats.long'))+ time.strftime(":%S ")
  end


end
