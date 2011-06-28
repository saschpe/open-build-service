class SourceServiceParameterChoice < ActiveRecord::Base
  validates_presence_of :value

  belongs_to :source_service_parameter

  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.choice(self.value)
  end
end
