class ParticipantsController < ApplicationController

  include ParticipantsHelper

  # load_and_authorize_resource
  # skip_authorize_resource :only => :showoffersbyuser

  before_filter :require_user, :only => [:show]

  # exibe participantes da unidade curricular
  def show
    name = session[:active_tab]
    id = params[:id]

    if id
      #localiza unidade curricular ativa
      @curriculum_unit = CurriculumUnit.find(id)

      #retorna perfil em que se pede matricula (~aluno)
      @student_profile = student_profile

      #retorna responsaveis pela turma
      @responsible = class_participants id, true
      
      #retorna participantes da turma (que nao sejam responsaveis)
      @participants = class_participants id, false

    end
    if current_user
      @user = User.find(current_user.id)
    end
  end

end
