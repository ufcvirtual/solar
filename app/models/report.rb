class Report

  attr_accessor :name_model, :total, :options_array

  def initialize (name_model, total)
    @name_model, @total = name_model, total
  end

  def self.query(query_type, ats_ids=nil, groups = nil)
    @options_array = Array.new(9)

    if(ats_ids)
      allocation_tags_ids = ats_ids.split(' ')
      if(allocation_tags_ids.size == 1)
        allocation_tag = AllocationTag.find(ats_ids)
        allocation_tags_ids = allocation_tag.related 
      else 
        allocation_tags_ids << AllocationTag.find(allocation_tags_ids.first).lower_related 
      end
      allocation_tags_ids = allocation_tags_ids.uniq.join(',')
    end  
    
    case query_type
      when '1'
        #reset_arrays #clean precausion..
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.info')
        @options_array[4] = I18n.t('reports.commun_texts.count')
        @options_array[9] = "#"
       
        models_info = Array.new(21)
        summary_array = Array.new(21)
        
        summary_array[0] = I18n.t('reports.summary.users_number')
        summary_array[1] = I18n.t('reports.summary.users_number_active')
        summary_array[2] = I18n.t('reports.summary.users_number_module_bound')
        summary_array[3] = I18n.t('reports.summary.users_number_module_unbound')
        summary_array[4] = I18n.t('reports.summary.number_of_students')
        summary_array[5] = I18n.t('reports.summary.courses_number')
        summary_array[6] = I18n.t('reports.summary.disciplines_amount')
        summary_array[7] = I18n.t('reports.summary.groups_number')
        summary_array[8] = I18n.t('reports.summary.groups_active_number')
        summary_array[9] = I18n.t('reports.summary.portifolio_number')
        summary_array[10] = I18n.t('reports.summary.files_portifolio')
        summary_array[11] = I18n.t('reports.summary.web_portifolio')
        summary_array[12] = I18n.t('reports.summary.webconferences_number')
        summary_array[13] = I18n.t('reports.summary.access_number_webconrence')
        summary_array[14] = I18n.t('reports.summary.discussion_number')
        summary_array[15] = I18n.t('reports.summary.post_number')
        summary_array[16] = I18n.t('reports.summary.lesson_number')
        summary_array[17] = I18n.t('reports.summary.material_number')
        summary_array[18] = I18n.t('reports.summary.chat_number')
        summary_array[19] = I18n.t('reports.summary.chat_message_number')
        summary_array[20] = I18n.t('reports.summary.access_number')

        #INFO QUERIES
        #quantidade de cursos
        models_info[5] = "#{Course.count}"
        #quantidade de usuarios
        models_info[0] = "#{User.count}"
        #quantidade de usuarios ativos
        models_info[1] = "#{User.where(:active => TRUE).count}"

        # 3 user com o campo integrado com o valor true, e que o cpf não consta na tabela user_blacklist
        @user_blacklist = UserBlacklist.all
        models_info[2] = User.count(:all, :conditions => ['integrated = TRUE and cpf NOT IN (?)', @user_blacklist.map(&:cpf)])
        # 4 user não vinculado ao modulo academico
        models_info[3] = User.count(:all, :conditions => ['integrated = FALSE or integrated = TRUE and cpf IN (?)', @user_blacklist.map(&:cpf)])

        #quantidade de Disciplinas
        models_info[6] = "#{CurriculumUnit.count}"
        #quantidade de Turmas
        models_info[7] = Group.count
        #quantidade de Turmas Ativas
        models_info[8] = Group.where("status=TRUE").count

        #Quantidade de Portfólios
        models_info[9] = Assignment.count  

        #Quantidade de arquivo postados
        models_info[10] = AssignmentFile.count

        #Quantidade de webconferencia postadas nas atividades
        models_info[11] = AssignmentWebconference.count

        #Quantidade de webconferencia 
        models_info[12] = Webconference.count

        #Quantidade de webconferencia 
        models_info[13] = LogAction.where("log_actions.log_type=#{LogAction::TYPE[:access_webconference]} ").count                

        #quantidade de fóruns
        models_info[14] = Discussion.count  

        #quantidade de postagens nos fóruns                    
        models_info[15] = Post.count      
        #Quantidade de Aulas
        models_info[16] = Lesson.count  
        #Quantidade de Material de Apoio
        models_info[17] = SupportMaterialFile.count    
        #Quantidade de Chat Romms
        models_info[18] = ChatRoom.count     
        #Quantidade de Messagens no Chat Romms
        models_info[19] = ChatMessage.count                                              
        #Quantidade de acessos
        models_info[20] = LogAccess.where("log_type=1").count

        #quantidade de alunos alocados no ambiente
        t_users = Profile.joins("LEFT JOIN allocations ON allocations.profile_id = profiles.id")
        .where("cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND allocations.status= 1")
        .select(" COUNT(DISTINCT user_id) as t").first
        models_info[4] = t_users.t

        list = []
        index = 0
        summary_array.each do |model|  
          list << Report.new(model, models_info[index])
          index = index + 1
        end
        return list  
      when '2'
        #reset_arrays #clean precausion..
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.info')
        @options_array[4] = I18n.t('reports.commun_texts.count')
        @options_array[9] = "#"
       
        models_info = Array.new
        summary_array = Array.new
        
        summary_array[0] = I18n.t('reports.summary.number_of_students')
        summary_array[1] = I18n.t('reports.summary.number_of_responsible')
        summary_array[2] = I18n.t('reports.summary.portifolio_number')
        summary_array[3] = I18n.t('reports.summary.files_portifolio')
        summary_array[4] = I18n.t('reports.summary.files_portifolio_distinct_user')
        summary_array[5] = I18n.t('reports.summary.web_portifolio')
        summary_array[6] = I18n.t('reports.summary.webconferences_number')
        summary_array[7] = I18n.t('reports.summary.access_number_webconrence')
        summary_array[8] = I18n.t('reports.summary.webconference_total')
        summary_array[9] = I18n.t('reports.summary.access_number_distinct_user_webconrence')
        summary_array[10] = I18n.t('reports.summary.access_number_responsables')
        summary_array[11] = I18n.t('reports.summary.discussion_number')
        summary_array[12] = I18n.t('reports.summary.post_number')
        summary_array[13] = I18n.t('reports.summary.lesson_number')
        summary_array[14] = I18n.t('reports.summary.material_number')
        summary_array[15] = I18n.t('reports.summary.chat_number')
        summary_array[16] = I18n.t('reports.summary.chat_message_number')
        summary_array[17] = I18n.t('reports.summary.exam_number')
        summary_array[18] = I18n.t('reports.summary.access_number')
        if groups.empty?
          summary_array[19] = I18n.t('reports.summary.groups_number')
          summary_array[20] = I18n.t('reports.summary.groups_active_number')
        end  

        #Quantidade de Portfólios
        models_info[2] = Assignment.joins("LEFT JOIN academic_allocations ON assignments.id = academic_allocations.academic_tool_id")
                                   .where("academic_allocations.academic_tool_type='Assignment' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})").count

        #Quantidade de arquivo postados
        models_info[3] = AssignmentFile.joins("LEFT JOIN academic_allocation_users ON assignment_files.academic_allocation_user_id = academic_allocation_users.id")
        .joins("LEFT JOIN academic_allocations ON academic_allocation_users.academic_allocation_id = academic_allocations.id")
        .joins("LEFT JOIN assignments ON assignments.id = academic_allocations.academic_tool_id")
        .where("academic_allocations.academic_tool_type='Assignment' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})").count

         #Quantidade de arquivo postados em portifolio distinto por usuários distinctos
        distinct_assingnment_file =  Assignment.joins("LEFT JOIN academic_allocations ON assignments.id = academic_allocations.academic_tool_id")
        .joins("LEFT JOIN academic_allocation_users ON academic_allocation_users.academic_allocation_id = academic_allocations.id")
        .joins("LEFT JOIN assignment_files ON assignment_files.academic_allocation_user_id = academic_allocation_users.id ")
        .where("academic_allocations.academic_tool_type='Assignment' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})")
        .select("COUNT(DISTINCT assignment_files.id) as t,  assignments.id, assignment_files.user_id")
        .group("assignments.id, assignment_files.user_id")


        total_distinct_assingnment_file = 0
        distinct_assingnment_file.each do |obj|
          if obj.t.to_i>0
            total_distinct_assingnment_file=total_distinct_assingnment_file+1 
          end  
        end  
        models_info[4] = total_distinct_assingnment_file #distinct_assingnment_file.to_a.count

        #Quantidade de webconferencia postadas nas atividades
        models_info[5] = AssignmentWebconference.joins("LEFT JOIN academic_allocation_users ON assignment_webconferences.academic_allocation_user_id = academic_allocation_users.id")
        .joins("LEFT JOIN academic_allocations ON academic_allocation_users.academic_allocation_id = academic_allocations.id")
        .joins("LEFT JOIN assignments ON assignments.id = academic_allocations.academic_tool_id")
        .where("academic_allocations.academic_tool_type='Assignment' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})").count

        #Quantidade de webconferencia 
        models_info[6] = Webconference.joins("LEFT JOIN academic_allocations ON webconferences.id = academic_allocations.academic_tool_id")
        .where("academic_allocations.academic_tool_type='Webconference' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})").count

        models_info[7] =  LogAction.joins("LEFT JOIN academic_allocations ON log_actions.academic_allocation_id = academic_allocations.id")
                            .joins("LEFT JOIN users ON users.id = log_actions.user_id") 
                            .joins("LEFT JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id = academic_allocations.allocation_tag_id") 
                            .joins("LEFT JOIN profiles ON profiles.id = allocations.profile_id")
                            .joins("LEFT JOIN webconferences ON webconferences.id = academic_allocations.academic_tool_id")
                            .where("academic_allocations.allocation_tag_id IN (#{allocation_tags_ids}) AND academic_allocations.academic_tool_type='Webconference' AND log_actions.log_type=#{LogAction::TYPE[:access_webconference]} AND (cast( profiles.types & '#{Profile_Type_Student}' as boolean ) OR cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean )) AND profiles.status= 't'").count                
                                             
  
        models_info[8] =  LogAction.joins("LEFT JOIN academic_allocations ON log_actions.academic_allocation_id = academic_allocations.id")
                            .joins("LEFT JOIN users ON users.id = log_actions.user_id") 
                            .joins("LEFT JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id = academic_allocations.allocation_tag_id") 
                            .joins("LEFT JOIN profiles ON profiles.id = allocations.profile_id")
                            .joins("LEFT JOIN webconferences ON webconferences.id = academic_allocations.academic_tool_id")
                            .where("academic_allocations.allocation_tag_id IN (#{allocation_tags_ids}) AND academic_allocations.academic_tool_type='Webconference' AND log_actions.log_type=#{LogAction::TYPE[:access_webconference]} AND (cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean )) AND profiles.status= 't'")
                            .select(" DISTINCT webconferences.id ").count 

        models_info[9] =  LogAction.joins("LEFT JOIN academic_allocations ON log_actions.academic_allocation_id = academic_allocations.id")
                            .joins("LEFT JOIN users ON users.id = log_actions.user_id") 
                            .joins("LEFT JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id = academic_allocations.allocation_tag_id") 
                            .joins("LEFT JOIN profiles ON profiles.id = allocations.profile_id")
                            .joins("LEFT JOIN webconferences ON webconferences.id = academic_allocations.academic_tool_id")
                            .where("academic_allocations.allocation_tag_id IN (#{allocation_tags_ids}) AND academic_allocations.academic_tool_type='Webconference' AND log_actions.log_type=#{LogAction::TYPE[:access_webconference]} AND (cast( profiles.types & '#{Profile_Type_Student}' as boolean ) OR cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean )) AND profiles.status= 't'")
                            .select(" DISTINCT users.id ").count   
        # Quantidade de acessos por responsáveis a webconferencia
        models_info[10] =  LogAction.joins("LEFT JOIN academic_allocations ON log_actions.academic_allocation_id = academic_allocations.id")
                            .joins("LEFT JOIN users ON users.id = log_actions.user_id") 
                            .joins("LEFT JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id = academic_allocations.allocation_tag_id") 
                            .joins("LEFT JOIN profiles ON profiles.id = allocations.profile_id")
                            .joins("LEFT JOIN webconferences ON webconferences.id = academic_allocations.academic_tool_id")
                            .where("academic_allocations.allocation_tag_id IN (#{allocation_tags_ids}) AND academic_allocations.academic_tool_type='Webconference' AND log_actions.log_type=#{LogAction::TYPE[:access_webconference]} AND (cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean )) AND profiles.status= 't'").count 

        #quantidade de fóruns
        models_info[11] = Discussion.joins("LEFT JOIN academic_allocations ON academic_allocations.academic_tool_id = discussions.id")
                            .where("academic_allocations.allocation_tag_id IN (#{allocation_tags_ids}) AND academic_allocations.academic_tool_type='Discussion'").count                
                
        models_info[12] = Post.joins("LEFT JOIN academic_allocations ON discussion_posts.academic_allocation_id = academic_allocations.id")
                            .joins("LEFT JOIN discussions ON academic_allocations.academic_tool_id = discussions.id")   
                            .where("academic_allocations.allocation_tag_id IN (#{allocation_tags_ids}) AND academic_allocations.academic_tool_type='Discussion'").count                
  
        #Quantidade de aulas
        models_info[13] = Lesson.joins("LEFT JOIN lesson_modules ON lessons.lesson_module_id = lesson_modules.id")
                                .joins("LEFT JOIN academic_allocations ON lesson_modules.id = academic_allocations.academic_tool_id")  
                                .where("academic_allocations.academic_tool_type='LessonModule' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})").count

        #Quantidade de Material de Apoio
        models_info[14] = SupportMaterialFile.joins("LEFT JOIN academic_allocations ON support_material_files.id = academic_allocations.academic_tool_id")
                                             .where("academic_allocations.academic_tool_type='SupportMaterialFile' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})").count                  
        
        #Quantidade de Chat Romms
        models_info[15] = ChatRoom.joins("LEFT JOIN academic_allocations ON  chat_rooms.id = academic_allocations.academic_tool_id")
                          .where("academic_allocations.academic_tool_type='ChatRoom' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})").count  

        #Quantidade de Messagens nos Chat Romms
        models_info[16] = ChatRoom.joins("LEFT JOIN academic_allocations ON  chat_rooms.id = academic_allocations.academic_tool_id")
                          .joins("LEFT JOIN chat_messages ON chat_messages.academic_allocation_id = academic_allocations.id")
                          .where("academic_allocations.academic_tool_type='ChatRoom' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})")
                          .select(" DISTINCT chat_messages.id ").count                    
       
        #Quantidade de Provas
        models_info[17] = Exam.joins("LEFT JOIN academic_allocations ON exams.id = academic_allocations.academic_tool_id")
                          .where("academic_allocations.academic_tool_type='Exam' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})").count                                     

        #Quantidade de acessos
        models_info[18] = LogAccess.where("allocation_tag_id IN (#{allocation_tags_ids})").count

        #turmas
        if groups.empty? 
          #Quantidade de Turmas
          ats = ats_ids.split(' ').map { |at| 
            groups = AllocationTag.find(at.to_i).groups
          }

          models_info[19] = groups.uniq.size
 
          models_info[20] = groups.where("status = TRUE").uniq.size
          
        end
       
        #quantidade de alunos alocados
        t_users = Profile.joins("LEFT JOIN allocations ON allocations.profile_id = profiles.id")
        .where("cast( profiles.types & '#{Profile_Type_Student}' as boolean ) AND allocations.status= 1 AND allocations.allocation_tag_id IN (#{allocation_tags_ids})")
        .select(" COUNT(DISTINCT user_id) as t").first
        models_info[0] = t_users.t

        #quantidade de responsáveis alocados
        t_users_r = Profile.joins("LEFT JOIN allocations ON allocations.profile_id = profiles.id")
        .where("cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean ) AND allocations.status= 1 AND allocations.allocation_tag_id IN (#{allocation_tags_ids})")
        .select(" COUNT(DISTINCT user_id) as t").first
        models_info[1] = t_users_r.t

        list = []
        index = 0
        summary_array.each do |model|  
          list << Report.new(model, models_info[index])
          index = index + 1
        end
        return list  
      when '3'
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.name_forum')
        @options_array[4] = I18n.t('reports.commun_texts.count')
        @options_array[9] = "#" #sempre o último todos os documentos tem
       
        models_info = Post.joins("LEFT JOIN academic_allocations ON discussion_posts.academic_allocation_id = academic_allocations.id")
                            .joins("LEFT JOIN discussions ON academic_allocations.academic_tool_id = discussions.id")   
                            .where("academic_allocations.allocation_tag_id IN (#{allocation_tags_ids}) AND academic_allocations.academic_tool_type='Discussion'")                
                            .select(" discussions.name AS name_model, COUNT(DISTINCT discussion_posts.id) AS total") 
                            .group("name_model")
                            .order("name_model")      

    when '4'
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.webconference')
        @options_array[4] = I18n.t('reports.commun_texts.access_number')
        @options_array[5] = I18n.t('reports.commun_texts.access_number_distinct')
        @options_array[6] = I18n.t('reports.commun_texts.access_number_responsables')
        @options_array[9] = "#" #sempre o último todos os documentos tem
       
         models_info = Webconference.joins("LEFT JOIN academic_allocations ON webconferences.id = academic_allocations.academic_tool_id")
                            .joins("LEFT JOIN log_actions ON log_actions.academic_allocation_id = academic_allocations.id AND log_actions.log_type=#{LogAction::TYPE[:access_webconference]}") 
                            .joins("LEFT JOIN users ON users.id = log_actions.user_id") 
                            .joins("LEFT JOIN allocations ON users.id = allocations.user_id AND allocations.allocation_tag_id = academic_allocations.allocation_tag_id")
                            .joins("LEFT JOIN profiles ON profiles.id = allocations.profile_id AND (cast( profiles.types & '#{Profile_Type_Student}' as boolean ) OR cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean )) AND profiles.status= 't'")
                            .where("academic_allocations.allocation_tag_id IN (#{allocation_tags_ids}) AND academic_allocations.academic_tool_type='Webconference'")                
                            .select(" webconferences.title AS name_model, COUNT(log_actions.id) AS total, COUNT(DISTINCT users.id) AS total1,  count(CASE WHEN cast( profiles.types & '#{Profile_Type_Class_Responsible}' as boolean ) THEN 1 END) AS total2 ") 
                            .group("name_model")
                            .order("name_model")      
    when '5'
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.webconference')
        @options_array[4] = I18n.t('reports.commun_texts.count')
        @options_array[9] = "#" #sempre o último todos os documentos tem
       
        models_info = ChatRoom.joins("LEFT JOIN academic_allocations ON  chat_rooms.id = academic_allocations.academic_tool_id")
                          .joins("LEFT JOIN chat_messages ON chat_messages.academic_allocation_id = academic_allocations.id")
                          .where("academic_allocations.academic_tool_type='ChatRoom' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})")
                          .select("chat_rooms.title AS name_model, COUNT(DISTINCT chat_messages.id) AS total ")    
                          .group("name_model")
                          .order("name_model") 

    when '6'
        @options_array[0] = 430
        @options_array[1] = @options_array[2] = 0
        @options_array[3] = I18n.t('reports.commun_texts.title_portfolio')
        @options_array[4] = I18n.t('reports.commun_texts.count')
        @options_array[5] = I18n.t('reports.commun_texts.number_distinct_user_portfolio')
        @options_array[9] = "#" #sempre o último todos os documentos tem
       
        models_info = Assignment.joins("LEFT JOIN academic_allocations ON assignments.id = academic_allocations.academic_tool_id")
                                .joins("LEFT JOIN academic_allocation_users ON academic_allocation_users.academic_allocation_id = academic_allocations.id")
                                .joins("LEFT JOIN assignment_files ON assignment_files.academic_allocation_user_id = academic_allocation_users.id ")
                                .where("academic_allocations.academic_tool_type='Assignment' AND academic_allocations.allocation_tag_id IN (#{allocation_tags_ids})")
                                .select("assignments.name AS name_model, COUNT(DISTINCT assignment_files.id) as total, COUNT(distinct assignment_files.user_id) as total1")
                                .group("name_model")
                                .order("name_model")                         
    end 
  end

  def self.get_options_array
  	@options_array
  end	

end