class Protocol < ActiveRecord::Base
  has_many :protocol_roles
  has_many :scan_procedures

  has_one :sharing, :as => :shareable, :dependent => :destroy

  def shareable?(category=nil)
  	!shareable.nil? ? sharing.shareable?(category) : true
  end

  def heal_sharing
    if self.sharing.nil?
      self.sharing = Sharing.new(:shareable => self)
      self.sharing.can_share = true
      self.sharing.can_share_adrc = false
      self.sharing.can_share_wrap = false
      self.sharing.can_share_internal = false
      self.sharing.can_share_up = false
      self.sharing.save
    end
  end

end
