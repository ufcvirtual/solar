module V1
  class Scores < Base

    namespace :groups do

      before do
        @at = AllocationTag.find_by_group_id(params[:id])
        @ats = RelatedTaggable.related(group_id: params[:id])
      end

      ## api/v1/groups/1/scores/info
      params { requires :id, type: Integer, desc: 'ID da turma' }
      get ':id/scores/info' do
        authorize! :info, Score, on: [@at.id]

        assignments, discussions, history_access = Score.informations(current_user.id, @at, related: @ats)

        hash_assignments = assignments.map do |assignment|
          situation = assignment.info(current_user, @at)

          comments = situation[:comments].map do |c|
            {
              user_id: c.user_id,
              user_name: c.user.name,
              comment: c.comment,
              created_at: c.updated_at
            }
          end rescue []

          date_info = assignment.schedule
          {
            id: assignment.id,
            type_assignment: assignment.type_assignment,
            name: assignment.name,
            enunciation: assignment.enunciation,
            situation: situation[:situation],
            grade: situation[:grade],
            start_date: date_info.start_date,
            end_date: date_info.end_date,
            comments: comments
          }
        end

        {
          assignments: hash_assignments,
          discussions: discussions.map { |d| {id: d.id, name: d.name, posts_count: d.posts_count.to_i} },
          history_access: history_access.map { |h| {created_at: h.created_at} }
        }

      end # get

    end # namespace

  end
end
