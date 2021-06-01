class Sharing < ActiveRecord::Base

  belongs_to :shareable, :polymorphic => true

  has_ancestry

  # def shareable?
  # 	!shareable.nil? ? shareable : true
  # end

  def category_to_field(category=nil)
  	case category
  	when :internal
  		:can_share_internal
  	when :WRAP
  		:can_share_wrap
  	when :ADRC
  		:can_share_adrc
  	when :UP
  		:can_share_up
  	else
  		:can_share
  	end
  end

  def shareable?(category=nil)

  	field_we_want = category_to_field(category)

    if !send(field_we_want).nil?
      send(field_we_want)
  	elsif is_root?
  		can_share and !!send(field_we_want)
  	else
  		ancestors.pluck(field_we_want).compact.inject(true){|value, other_value| value && other_value}
  	end

  end

  def inherit(force=nil)
    # puts "force is #{force}"

    force = !!force
    # puts "boolified force is #{force}"

    # puts "can_share.nil? (#{self.can_share.nil?}) or force (#{force}) == #{self.can_share.nil? or force}"
    if self.can_share.nil? or force
      self.can_share = shareable?
      # puts "now can_share is #{self.can_share}"
    end

    # puts "can_share_adrc.nil? (#{self.can_share_adrc.nil?}) or force (#{force}) == #{self.can_share_adrc.nil? or force}"
    if self.can_share_adrc.nil? or force
      self.can_share_adrc = shareable?(:ADRC)
      # puts "now can_share_adrc is #{self.can_share_adrc}"
    end

    # puts "can_share_wrap.nil? (#{self.can_share_wrap.nil?}) or force (#{force}) == #{self.can_share_wrap.nil? or force}"
    if self.can_share_wrap.nil? or force
      self.can_share_wrap = shareable?(:WRAP)
      # puts "now can_share_wrap is #{self.can_share_wrap}"
    end

    # puts "can_share_up.nil? (#{self.can_share_up.nil?}) or force (#{force}) == #{self.can_share_up.nil? or force}"
    if self.can_share_up.nil? or force
      self.can_share_up = shareable?(:UP)
      # puts "now can_share_up is #{self.can_share_up}"
    end

    # puts "can_share_internal.nil? (#{self.can_share_internal.nil?}) or force (#{force}) == #{self.can_share_internal.nil? or force}"
    if self.can_share_internal.nil? or force
      self.can_share_internal = shareable?(:internal)
      # puts "now can_share_internal is #{self.can_share_internal}"
    end

    self.save!

  end

end

# CREATE TABLE `sharings` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `created_at` datetime DEFAULT NULL,
#   `updated_at` datetime DEFAULT NULL,
#   `shareable_id` int DEFAULT NULL,
#   `shareable_type` varchar(255) DEFAULT NULL,
#   `ancestry` varchar(255) DEFAULT NULL,
#   `can_share` tinyint(1) DEFAULT 1,
#   `can_share_internal` tinyint(1) DEFAULT NULL,
#   `can_share_wrap` tinyint(1) DEFAULT NULL,
#   `can_share_adrc` tinyint(1) DEFAULT NULL,
#   `can_share_up` tinyint(1) DEFAULT NULL,
#   PRIMARY KEY (`id`),
#   KEY `index_sharing_on_ancestry` (`ancestry`)
# )