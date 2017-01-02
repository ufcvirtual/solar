class Report

  attr_accessor :name_model, :total, :options_array

  def initialize (name_model, total)
    @name_model, @total = name_model, total
  end

  def self.query(query_type, period, type)
    @options_array = Array.new(9)
    case query_type
      when '1'
        #reset_arrays #clean precausion..
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.info')
        @options_array[4] = I18n.t('reports.commun_texts.count')
        @options_array[9] = "#"
       
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
        # query numero de alunos por curso
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.name_course')
        @options_array[4] = I18n.t('reports.commun_texts.number_students')
        @options_array[9] = "#"

        g1 = ""
        g2 = ""
        g3 = ""
        g4 = ""
        if type=='courses'
        	selectd = "DISTINCT CONCAT(c1.name, c2.name, c3.name, c4.name) AS name_model,  COUNT(DISTINCT allocations.user_id) AS total"
          @options_array[3] = I18n.t('reports.commun_texts.name_course')

        elsif type=='curriculum_units'  
        	selectd = "DISTINCT CONCAT(cm1.name,cm2.name,cm3.name,cm4.name) AS name_model,  COUNT(DISTINCT allocations.user_id) AS total"
          @options_array[3] = I18n.t('reports.commun_texts.name_disciplines')
        
        elsif type=='groups'  
        	g1 = " AND g1.status = TRUE " 
        	g2 = " AND g2.status = TRUE "
        	g3 = " AND g3.status = TRUE "
        	g4 = " AND g3.status = TRUE "             
          selectd = "CASE WHEN CONCAT(c1.name, c2.name, c3.name,c4.name)=CONCAT(cm1.name,cm2.name,cm3.name, cm4.name) THEN CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name),' - ', CONCAT(g1.code, g2.code, g3.code, g4.code))   
          WHEN CONCAT(cm1.name,cm2.name,cm3.name, cm4.name)='' THEN CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name),' - ',CONCAT(g1.code, g2.code, g3.code, g4.code)) 
          ELSE CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ', CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ', CONCAT(g1.code, g2.code, g3.code, g4.code)) 
					END AS name_model,  COUNT(DISTINCT allocations.user_id) AS total"

          @options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')+' - '+I18n.t('reports.commun_texts.name_groups')
        else    
        	selectd = "CASE WHEN CONCAT(c1.name, c2.name, c3.name,c4.name)=CONCAT(cm1.name,cm2.name,cm3.name, cm4.name) THEN CONCAT(c1.name, c2.name, c3.name,c4.name) 
        	WHEN CONCAT(cm1.name,cm2.name,cm3.name, cm4.name)='' THEN CONCAT(c1.name, c2.name, c3.name,c4.name) 
        	ELSE CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ', CONCAT(cm1.name,cm2.name,cm3.name, cm4.name)) 
					END AS name_model,  COUNT(DISTINCT allocations.user_id) AS total"        

          @options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')
        end  

        models_info = Profile.joins("LEFT JOIN allocations ON allocations.profile_id = profiles.id AND allocations.status=1 AND cast( profiles.types & '#{Profile_Type_Student}' as boolean )")
                            .joins("LEFT JOIN allocation_tags ON allocations.allocation_tag_id = allocation_tags.id ")
                            .joins("LEFT JOIN related_taggables AS r1 ON allocation_tags.group_id = r1.group_id")
                            .joins("LEFT JOIN related_taggables AS r2 ON allocation_tags.offer_id = r2.offer_id")
                            .joins("LEFT JOIN related_taggables AS r3 ON allocation_tags.curriculum_unit_id = r3.curriculum_unit_id")
                            .joins("LEFT JOIN related_taggables AS r4 ON allocation_tags.course_id = r4.course_id")
                            .joins("LEFT JOIN courses AS c1 ON r1.course_id = c1.id")
                            .joins("LEFT JOIN courses AS c2 ON r2.course_id = c2.id")
                            .joins("LEFT JOIN courses AS c3 ON r3.course_id = c3.id")
                            .joins("LEFT JOIN courses AS c4 ON r4.course_id = c4.id")
                            .joins("LEFT JOIN curriculum_units AS cm1 ON r1.curriculum_unit_id = cm1.id")
                            .joins("LEFT JOIN curriculum_units AS cm2 ON r2.curriculum_unit_id = cm2.id")
                            .joins("LEFT JOIN curriculum_units AS cm3 ON r3.curriculum_unit_id = cm3.id")
                            .joins("LEFT JOIN curriculum_units AS cm4 ON r4.curriculum_unit_id = cm4.id")
                            .joins("LEFT JOIN groups AS g1 ON r1.group_id = g1.id" + g1)
                            .joins("LEFT JOIN groups AS g2 ON r2.group_id = g2.id" + g2)
                            .joins("LEFT JOIN groups AS g3 ON r3.group_id = g3.id" + g3)
                            .joins("LEFT JOIN groups AS g4 ON r4.group_id = g4.id" + g4)
                            .where("(r1.semester_id=#{period} OR r2.semester_id=#{period} OR r3.semester_id=#{period} OR r4.semester_id=#{period}) ")
                            .select(selectd) 
                            .group("name_model")
                            .order("name_model")        
      when '3'
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.name_course')
        @options_array[4] = I18n.t('reports.commun_texts.number_disciplines')
        @options_array[9] = "#"

        models_info = Course.joins("courses LEFT JOIN related_taggables ON courses.id = related_taggables.course_id AND semester_id= #{period}")
                            .select("courses.name AS name_model, COUNT(DISTINCT curriculum_unit_id) AS total")
                            .group("name_model")
                            .order("name_model") 

      when '4' 
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.name_disciplines')
        @options_array[4] = I18n.t('reports.commun_texts.count')
        @options_array[9] = "#" #sempre o último todos os documentos tem
        g1 = ""
        g2 = ""
        g3 = ""
        g4 = ""
        if type=='courses'
          selectd = "DISTINCT CONCAT(c1.name, c2.name, c3.name, c4.name) AS name_model,  COUNT(DISTINCT allocations.user_id) AS total"
          @options_array[3] = I18n.t('reports.commun_texts.name_course')
        elsif type=='curriculum_units'  
         selectd = "DISTINCT CONCAT(cm1.name,cm2.name,cm3.name,cm4.name) AS name_model,  COUNT(DISTINCT allocations.user_id) AS total"
          @options_array[3] = I18n.t('reports.commun_texts.name_disciplines')
        elsif type=='groups'    
          g1 = " AND g1.status = TRUE " 
        	g2 = " AND g2.status = TRUE "
        	g3 = " AND g3.status = TRUE "
        	g4 = " AND g3.status = TRUE "             
          selectd = "CASE WHEN CONCAT(c1.name, c2.name, c3.name,c4.name)=CONCAT(cm1.name,cm2.name,cm3.name, cm4.name) THEN CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name),' - ', CONCAT(g1.code, g2.code, g3.code, g4.code))   
          WHEN CONCAT(cm1.name,cm2.name,cm3.name, cm4.name)='' THEN CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name),' - ',CONCAT(g1.code, g2.code, g3.code, g4.code)) 
          ELSE CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ', CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ', CONCAT(g1.code, g2.code, g3.code, g4.code)) 
					END AS name_model,  COUNT(DISTINCT allocations.user_id) AS total"
					@options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')+' - '+I18n.t('reports.commun_texts.name_groups')
        else  
         selectd = "CASE WHEN CONCAT(c1.name, c2.name, c3.name,c4.name)=CONCAT(cm1.name,cm2.name,cm3.name, cm4.name) THEN CONCAT(c1.name, c2.name, c3.name,c4.name) 
        	WHEN CONCAT(cm1.name,cm2.name,cm3.name, cm4.name)='' THEN CONCAT(c1.name, c2.name, c3.name,c4.name) 
        	ELSE CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ', CONCAT(cm1.name,cm2.name,cm3.name, cm4.name)) 
					END AS name_model,  COUNT(DISTINCT allocations.user_id) AS total"        

          @options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')
        end  
       
        models_info = Profile.joins("LEFT JOIN allocations ON allocations.profile_id = profiles.id AND cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean ) AND allocations.status= 1")
                            .joins("LEFT JOIN allocation_tags ON allocations.allocation_tag_id = allocation_tags.id ")
                            .joins("LEFT JOIN related_taggables AS r1 ON allocation_tags.group_id = r1.group_id")
                            .joins("LEFT JOIN related_taggables AS r2 ON allocation_tags.offer_id = r2.offer_id")
                            .joins("LEFT JOIN related_taggables AS r3 ON allocation_tags.curriculum_unit_id = r3.curriculum_unit_id")
                            .joins("LEFT JOIN related_taggables AS r4 ON allocation_tags.course_id = r4.course_id")
                            .joins("LEFT JOIN courses AS c1 ON r1.course_id = c1.id")
                            .joins("LEFT JOIN courses AS c2 ON r2.course_id = c2.id")
                            .joins("LEFT JOIN courses AS c3 ON r3.course_id = c3.id")
                            .joins("LEFT JOIN courses AS c4 ON r4.course_id = c4.id")
                            .joins("LEFT JOIN curriculum_units AS cm1 ON r1.curriculum_unit_id = cm1.id")
                            .joins("LEFT JOIN curriculum_units AS cm2 ON r2.curriculum_unit_id = cm2.id")
                            .joins("LEFT JOIN curriculum_units AS cm3 ON r3.curriculum_unit_id = cm3.id")
                            .joins("LEFT JOIN curriculum_units AS cm4 ON r4.curriculum_unit_id = cm4.id")
                            .joins("LEFT JOIN groups AS g1 ON r1.group_id = g1.id" + g1)
                            .joins("LEFT JOIN groups AS g2 ON r2.group_id = g2.id" + g2)
                            .joins("LEFT JOIN groups AS g3 ON r3.group_id = g3.id" + g3)
                            .joins("LEFT JOIN groups AS g4 ON r4.group_id = g4.id" + g4)
                            .where("(r1.semester_id=#{period} OR r2.semester_id=#{period} OR r3.semester_id=#{period} OR r4.semester_id=#{period}) ")
                            .select(selectd) 
                            .group("name_model")
                            .order("name_model") 

      when '5'
       # reset_arrays #clean precausion..
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        #$options_array[3] = I18n.t('reports.commun_texts.name_forum')
        @options_array[4] = I18n.t('reports.commun_texts.count')
        @options_array[9] = "#" #sempre o último todos os documentos tem
        g1 = ""
        g2 = ""
        g3 = ""
        g4 = ""
        if type=='courses'
          selectd = "CASE WHEN CONCAT(c1.name, c2.name, c3.name,c4.name)=CONCAT(cm1.name,cm2.name,cm3.name, cm4.name) THEN CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ',  discussions.name )
          ELSE CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ', CONCAT(cm1.name,cm2.name,cm3.name, cm4.name), ' - ',  discussions.name ) END AS name_model, COUNT(DISTINCT discussion_posts) AS total" 
          @options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+ I18n.t('reports.commun_texts.name_forum')

        elsif type=='curriculum_units'  
          selectd = "CONCAT(CONCAT(cm1.name,cm2.name,cm3.name, cm4.name), ' - ', discussions.name) AS name_model, COUNT(DISTINCT discussion_posts) AS total"
          @options_array[3] = I18n.t('reports.commun_texts.name_disciplines')+' - '+ I18n.t('reports.commun_texts.name_forum')
        elsif type=='groups'   
        	g1 = " AND g1.status = TRUE " 
        	g2 = " AND g2.status = TRUE "
        	g3 = " AND g3.status = TRUE "
        	g4 = " AND g3.status = TRUE "  
          selectd = "CASE WHEN CONCAT(c1.name, c2.name, c3.name,c4.name)=CONCAT(cm1.name,cm2.name,cm3.name, cm4.name) THEN CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ',  CONCAT(g1.code, g2.code, g3.code, g4.code), ' - ',  discussions.name )
          ELSE CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ', CONCAT(cm1.name,cm2.name,cm3.name, cm4.name), ' - ',  CONCAT(g1.code, g2.code, g3.code, g4.code), ' - ',  discussions.name ) END AS name_model, COUNT(DISTINCT discussion_posts) AS total"
          @options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')+' - '+I18n.t('reports.commun_texts.name_groups')+' - '+ I18n.t('reports.commun_texts.name_forum')
        else  
          selectd = "CASE WHEN CONCAT(c1.name, c2.name, c3.name,c4.name)=CONCAT(cm1.name,cm2.name,cm3.name, cm4.name) THEN CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ',  discussions.name )
          ELSE CONCAT(CONCAT(c1.name, c2.name, c3.name,c4.name), ' - ', CONCAT(cm1.name,cm2.name,cm3.name, cm4.name), ' - ',  discussions.name ) END AS name_model, count(DISTINCT discussion_posts.id) AS total"
          @options_array[3] = I18n.t('reports.commun_texts.name_course')+' - '+I18n.t('reports.commun_texts.name_disciplines')+' - '+ I18n.t('reports.commun_texts.name_forum')
        end  

        models_info = Discussion.joins("LEFT JOIN academic_allocations ON discussions.id = academic_allocations.academic_tool_id AND academic_tool_type='Discussion'")
                            .joins("LEFT JOIN discussion_posts ON academic_allocations.id = discussion_posts.academic_allocation_id")
                            .joins("LEFT JOIN allocation_tags ON allocation_tags.id = academic_allocations.allocation_tag_id")
                            .joins("LEFT JOIN related_taggables AS r1 ON allocation_tags.group_id = r1.group_id")
                            .joins("LEFT JOIN related_taggables AS r2 ON allocation_tags.offer_id = r2.offer_id")
                            .joins("LEFT JOIN related_taggables AS r3 ON allocation_tags.curriculum_unit_id = r3.curriculum_unit_id")
                            .joins("LEFT JOIN related_taggables AS r4 ON allocation_tags.course_id = r4.course_id")
                            .joins("LEFT JOIN courses AS c1 ON r1.course_id = c1.id")
                            .joins("LEFT JOIN courses AS c2 ON r2.course_id = c2.id")
                            .joins("LEFT JOIN courses AS c3 ON r3.course_id = c3.id")
                            .joins("LEFT JOIN courses AS c4 ON r4.course_id = c4.id")
                            .joins("LEFT JOIN curriculum_units AS cm1 ON r1.curriculum_unit_id = cm1.id")
                            .joins("LEFT JOIN curriculum_units AS cm2 ON r2.curriculum_unit_id = cm2.id")
                            .joins("LEFT JOIN curriculum_units AS cm3 ON r3.curriculum_unit_id = cm3.id")
                            .joins("LEFT JOIN curriculum_units AS cm4 ON r4.curriculum_unit_id = cm4.id")
                            .joins("LEFT JOIN groups AS g1 ON r1.group_id = g1.id" + g1)
                            .joins("LEFT JOIN groups AS g2 ON r2.group_id = g2.id" + g2)
                            .joins("LEFT JOIN groups AS g3 ON r3.group_id = g3.id" + g3)
                            .joins("LEFT JOIN groups AS g4 ON r4.group_id = g4.id" + g4)                         
                            .where("(r1.semester_id=#{period} OR r2.semester_id=#{period} OR r3.semester_id=#{period} OR r4.semester_id=#{period}) ")
                            .select(selectd) 
                            .group("name_model")
                            .order("name_model")      
    end 
  end

  def self.get_options_array
  	@options_array
  end	

end