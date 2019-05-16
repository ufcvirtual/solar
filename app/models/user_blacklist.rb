class UserBlacklist < ActiveRecord::Base
  include PersonCpf
  include APILog

  #default_scope order: 'name ASC'

  belongs_to :user

  validates :name, presence: true

  validate :cpf_can_go_to_blacklist?

  def order
   'name ASC'
  end

  def self.search(text)
    text = [URI.unescape(text).split(' ').compact.join("%"), "%"].join
    where("lower(unaccent(cpf || ' ' || name)) LIKE lower(unaccent(?))", "%#{self.cpf_without_mask(text)}")
  end

  private

    def cpf_can_go_to_blacklist?
      if user = User.find_by_cpf(self.cpf)
        ma_config = User::MODULO_ACADEMICO
        return true if ma_config.nil? || !ma_config['professor_profile'].present?
        user_data = User.connect_and_import_user(self.cpf)

        # even so the user can't be unbinded, if SI3 doesn't return it, it can.
        return true if user_data.blank?

        # verifica se user eh aluno ou professor em um curso a distancia
        al = user.allocations.joins(group: { offer: { curriculum_unit: :curriculum_unit_type } })
          .where(curriculum_unit_types: { allows_enrollment: false }, profile_id: [1, ma_config['professor_profile']]) # 1: aluno, 17: professor titular a distancia

        return true if al.empty?

        if user_data.class == String
          errors.add(:base, user_data)
          return false
        else
          errors.add(:cpf, I18n.t('user_blacklist.cpf_cannot_be_added'))
          return false
        end
      end

      return true
    end

    def self.related_with_uab(cpf)
      ma_config = User::MODULO_ACADEMICO
      return false if ma_config.nil? || !ma_config['professor_profile'].present?
      user = User.find_by_cpf(cpf)
      return false if user.blank?
      al = user.allocations.joins(group: { offer: { curriculum_unit: :curriculum_unit_type } })
          .where(curriculum_unit_types: { allows_enrollment: false }, profile_id: [1, ma_config['professor_profile']]) # 1: aluno, 17: professor titular a distancia
      return al.any?
    end

end
