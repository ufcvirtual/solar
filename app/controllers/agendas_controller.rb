# encoding: UTF-8
class AgendasController < ApplicationController
  before_filter :prepare_for_group_selection, only: :list

  layout false, only: [:calendar, :dropdown_content, :index, :events]

  before_filter except: :dropdown_content do
    ats = if active_tab[:url].include?(:allocation_tag_id) # entrou na turma
            AllocationTag.find(active_tab[:url][:allocation_tag_id]).related
          elsif params[:allocation_tags_ids].blank?
            current_user.activated_allocation_tag_ids(true, true)
          else # passou a turma como parametro
            params[:allocation_tags_ids].split(' ').flatten.map(&:to_i)
          end
    @allocation_tags_ids = ats.uniq
  end

  after_filter only: [:list, :events] do
    @allocation_tags_ids = @allocation_tags_ids.join(' ') unless @allocation_tags_ids.nil?
  end

  def index
    authorize! :calendar, Agenda, on: @allocation_tags_ids, read: true
    @schedules = Agenda.events(@allocation_tags_ids, @date = params[:date].to_date.to_formatted_s(:db))
  rescue CanCan::AccessDenied
    @schedules = []
  end

  def list
    render action: :calendar
  end

  def calendar
    @allocation_tags_ids = @allocation_tags_ids.join(' ')
    user_profiles = current_user.resources_by_allocation_tags_ids(@allocation_tags_ids)

    @access_forms = Event.descendants.collect do |model|
      model_name = model.to_s.tableize.singularize
      if model.constants.include?("#{params[:selected].try(:upcase)}_PERMISSION".to_sym)
        case model_name
        when 'chat_room'
          model_name if user_profiles.include?(chat_rooms: :index)
        when 'discussion'
          model_name if user_profiles.include?(discussions: :list)
        when 'assignment'
          model_name if user_profiles.include?(assignments: :index)
        when 'schedule_event'
          model_name if user_profiles.include?(schedule_events: :list)
        end
      end
    end

    @access_forms = @access_forms.compact.join(',')
  end

  def events
    authorize! :calendar, Agenda, on: @allocation_tags_ids, read: true

    render json: [Event.all_descendants(@allocation_tags_ids, current_user, params.include?('list'), params)].flatten.map(&:schedule_json).uniq
  end

  def dropdown_content
    @model_name = model_by_param_type(params[:type])
    @event      = @model_name.find(params[:id])
    @groups     = @event.groups
    @allocation_tags_ids = params[:allocation_tags_ids]
  end

  private

  def model_by_param_type(type)
    type.constantize if ['Assignment', 'Discussion', 'ChatRoom', 'ScheduleEvent', 'Lesson', 'Exam'].include?(type)
  end
end
