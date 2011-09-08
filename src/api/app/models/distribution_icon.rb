class DistributionIcon < ActiveRecord::Base
  validates_presence_of :url, :width, :height
  # TODO: Allow file-upload later on, probably thru CarrierWave gem

  has_and_belongs_to_many :distributions
end
