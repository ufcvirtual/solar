class Sav < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # self.primary_keys = :sav_id, :group_id

  belongs_to :group

  validates :sav_id, :start_date, :end_date, presence: true
  validates :sav_id, uniqueness: { scope: :group_id }

  validate :end_after_start
 
  def end_after_start
    errors.add(:end_date, "deve ser depois do início") unless end_date >= start_date
  end

  def self.current_savs(group_id)
    Sav.where("group_id = ? OR group_id IS NULL", group_id).where("? BETWEEN start_date AND end_date", Date.today).pluck(:sav_id)
  end

  # private
  #   def self.get_current_savs(group_id)
  #     unless SavConfig::CONFIG.nil?
  #       cipher = OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC')
  #       cipher.encrypt
  #       cipher.iv, cipher.key  = SavConfig::IV, SavConfig::KEY

  #       user_profiles = User.current.profiles.where('(allocations.allocation_tag_id IN (?) OR allocations.allocation_tag_id IS NULL)', AllocationTag.find_by_group_id(group_id).related).pluck(:id).to_s.delete("[]")
  #       savs = Sav.current_savs(group_id).to_s.delete("[]")
  #       @_sav_url = (savs.empty? ? "" : [SavConfig::URL, Base64.encode64(cipher.update(SavConfig::PARAMS.gsub("user_id", User.current.id.to_s).gsub("profiles_ids", user_profiles).gsub("savs_ids", savs)) + cipher.final).gsub("\n",'')].join.html_safe)
  #     end
  #   end

end
