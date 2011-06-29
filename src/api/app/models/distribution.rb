class Distribution < ActiveRecord::Base
  validates_presence_of :vendor, :version, :name

  has_and_belongs_to_many :icons, :class_name => 'DistributionIcon'
end
