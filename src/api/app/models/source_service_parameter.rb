class SourceServiceParameter < ActiveRecord::Base
  validates_presence_of :name

  belongs_to :source_service
  has_many :choices, :class_name => 'SourceServiceParameterChoice', :dependent => :destroy

  def to_xml(options = {})
    options[:include] ||= :choices
    options[:except] = [:id, :source_service_id]
    super(options)
  end

  def to_json(options = {})
    options[:include] ||= :choices
    options[:except] = [:id, :source_service_id]
    super(options)
  end
end
