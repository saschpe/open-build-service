class SourceServicesController < ApplicationController
  skip_before_filter :extract_user, :only => [:index, :show]
  before_filter :update_service_state, :only => [:index, :show]

  # GET /source_services
  # GET /source_services.xml
  # GET /source_services.json
  def index
    @source_services = SourceService.all()

    respond_to do |format|
      format.xml  { render :xml => @source_services }
      format.json { render :json => @source_services }
    end
  end

  # GET /source_services/download_file
  # GET /source_services/download_file.xml
  # GET /source_services/download_file.json
  def show
    @source_service = SourceService.find_by_name(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @source_service }
      format.json { render :json => @source_service }
    end
  end

private
  def update_service_state
    Rails.cache.fetch('service_backend_state', :expires_in => 60.minutes, :shared => true) do
      logger.debug 'Updating source services from backend...'

      # Drop all cached data, will be re-read from backend
      SourceService.delete_all()
      SourceServiceParameter.delete_all()
      SourceServiceParameterChoice.delete_all()

      data = REXML::Document.new(backend_get('/service')) # Parse backend XML
      data.root.each_element('service') do |service|
        @service = SourceService.create(:name => service.attributes['name'],
                                        :summary => service.elements['summary'].text,
                                        :description => service.elements['description'].text)
        service.each_element('parameter') do |param|
          @parameter = SourceServiceParameter.create(:name => param.attributes['name'],
                                                     :description => param.elements['description'].text,
                                                     :required => !param.elements['required'].nil?)
          @service.parameters << @parameter
          param.each_element('allowedvalue') do |choice|
            @choice = SourceServiceParameterChoice.create(:value => choice.text)
            @parameter.choices << @choice
          end
          @parameter.save
        end
        @service.save
      end
    end
  end
end
