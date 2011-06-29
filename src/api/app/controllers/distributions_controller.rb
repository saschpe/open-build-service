class DistributionsController < ApplicationController
  # Distribution list is insensitive information, no login needed therefore
  skip_before_filter :extract_user, :only => [:index, :show]
  before_filter :require_admin, :except => [:index, :show]

  # GET /distributions
  # GET /distributions.xml
  def index
    @distributions = Distribution.all

    respond_to do |format|
      format.xml  { render :xml => @distributions }
      format.json { render :json => @distributions }
    end
  end

  # GET /distributions/opensuse-11.4
  # GET /distributions/opensuse-11.4.xml
  def show
    @distribution = Distribution.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @distribution }
      format.json { render :json => @distribution }
    end
  end

  # POST /distributions
  # POST /distributions.xml
  def create
    begin
      @distribution = Distribution.new(request.request_parameters)
    rescue ActiveRecord::UnknownAttributeError
      # User didn't really upload www-form-urlencoded data but raw XML, try to parse that
      xml = REXML::Document.new(request.raw_post)
      attribs = {}
      # TODO: implement
      #attribs[:title] = xml.elements['/configuration/title'].text if xml.elements['/configuration/title']
      #attribs[:description] = xml.elements['/configuration/description'].text if xml.elements['/configuration/description']
      @distribution = Distribution.new(attribs)
    end

    respond_to do |format|
      if @distribution.save
        format.xml  { render :xml => @distribution, :status => :created, :location => @distribution }
        format.json { render :json => @distribution, :status => :created, :location => @distribution }
      else
        format.xml  { render :xml => @distribution.errors, :status => :unprocessable_entity }
        format.json { render :json => @distribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /distributions/opensuse-11.4
  # PUT /distributions/opensuse-11.4.xml
  def update
    @distribution = Distribution.find(params[:id])

    respond_to do |format|
      begin
        @distribution.update_attributes(request.request_parameters)
      rescue ActiveRecord::UnknownAttributeError
        # User didn't really upload www-form-urlencoded data but raw XML, try to parse that
        xml = REXML::Document.new(request.raw_post)
        attribs = {}
        # TODO: implement
        #attribs[:title] = xml.elements['/configuration/title'].text if xml.elements['/configuration/title']
        #attribs[:description] = xml.elements['/configuration/description'].text if xml.elements['/configuration/description']
        @distribution.update_attributes(attribs)
      end
      if @distribution.update_attributes(params[:distribution])
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.xml  { render :xml => @distribution.errors, :status => :unprocessable_entity }
        format.json { render :json => @distribution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /distributions/opensuse-11.4
  # DELETE /distributions/opensuse-11.4.xml
  def destroy
    @distribution = Distribution.find(params[:id])
    @distribution.destroy

    respond_to do |format|
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end
end
