class SourceService < ActiveRecord::Base
  validates_presence_of :name

  has_many :parameters, :class_name => 'SourceServiceParameter', :dependent => :destroy

  def to_xml(options = {})
    options[:include] ||= :parameters
    options[:except] = [:id]
    super(options)
  end

  def to_json(options = {})
    options[:include] ||= :parameters
    options[:except] = [:id]
    super(options)
  end
end
