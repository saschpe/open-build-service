class ApidocsController < ApplicationController

  include ApplicationHelper
  # Apidocs is insensitive static information, no login needed therefore
  skip_before_filter :extract_user
  
  def root
    redirect_to action: :index
  end

  # the main purpose of this subfunction is easier stubing
  def indexpath
    filename = File.expand_path(CONFIG['apidocs_location']) + "/index"
    if !File.exist?( filename + ".html" )
      return nil
    else
      return filename
    end
  end

  def index
    unless filename = indexpath
      flash[:error] = "Unable to load API documentation source file: #{CONFIG['apidocs_location']}"
      redirect_back_or_to :controller => 'main', :action => 'index'
    else
      render :file => filename, formats: [:html]
    end
  end

  def file
    file = File.expand_path( File.join(CONFIG['schema_location'], params[:filename]) )
    if File.exist?( file )
      send_file( file, :type => "text/xml", :disposition => "inline" )
    else
      flash[:error] = "File not found: #{params[:filename]}"
      redirect_back_or_to :controller => 'apidocs', :action => 'index'
    end
    return
  end

end
