require 'net/http'

class HomeController < ApplicationController

  before_filter :require_login, :except => [:my_work, :icon]
  before_filter :check_user, :except => [:icon]
  before_filter :overwrite_user, :only => [:index, :my_work, :requests, :list_my]

  def index
    #@requests_in = BsRequest.list({})
    #  [
    #   BsRequest.list({:states => 'review', :reviewstates => 'new', :roles => "reviewer", :user => login}),
    #   BsRequest.list({:states => 'new', :roles => "maintainer", :user => login})]
    #@requests_out = BsRequest.list({:states => 'new,review', :user => login, :roles => 'creator'})
    @roles = Role.local_roles
    @projects = @displayed_user.involved_projects.each.map {|x| x.name}.uniq.sort
    @packages = {}
    pkglist = @displayed_user.involved_packages.each.reject {|x| @projects.include?(x.project)}
    pkglist.sort(&@displayed_user.method('packagesorter')).each do |pack|
      @packages[pack.project] ||= []
      @packages[pack.project] << pack.name if !@packages[pack.project].include? pack.name
    end
  end

  def icon
    user = params[:id]
    size = params[:size] || '20'
    key = "home_face_#{user}_#{size}"
    Rails.cache.delete(key) if discard_cache?
    content = Rails.cache.fetch(key, :expires_in => 5.hour) do

      email = Person.email_for_login(user)
      hash = Digest::MD5.hexdigest(email.downcase)
      http = Net::HTTP.new("www.gravatar.com")
      begin
        http.start
        response, content = http.get "/avatar/#{hash}?s=#{size}&d=wavatar" unless Rails.env.test?
	content = nil unless response.is_a?(Net::HTTPSuccess)
      rescue SocketError, Errno::EINTR, Errno::EPIPE, EOFError, Net::HTTPBadResponse, IOError, Errno::ETIMEDOUT, Errno::ECONNREFUSED => err
	logger.debug "#{err} when fetching http://www.gravatar.com/avatar/#{hash}?s=#{size}"
        http = nil
      end
      http.finish if http

      unless content
        f = File.open("#{RAILS_ROOT}/public/images/local/default_face.png", "r")
        content = f.read
        f.close
      end
      content.force_encoding("ASCII-8BIT")
    end

    render :text => content, :layout => false, :content_type => "image/png"
  end

  def my_work
    unless @displayed_user
      require_login
      return
    end
    @declined_requests, @open_reviews, @new_requests = @displayed_user.requests_that_need_work(:cache => false)
    @open_patchinfos = @displayed_user.running_patchinfos(:cache => false)
    session[:requests] = (@declined_requests + @open_reviews  + @new_requests).each.map {|r| Integer(r.value(:id)) }
    respond_to do |format|
      format.html
      format.json do
        rawdata = Hash.new
        rawdata["declined"] = @declined_requests
        rawdata["review"] = @open_reviews
        rawdata["new"] = @new_requests
        rawdata["patchinfos"] = @open_patchinfos
        render :text => JSON.pretty_generate(rawdata)
      end
    end
  end

  def requests
    @requests = @displayed_user.involved_requests(:cache => false)
    session[:requests] = @requests.each.map {|r| Integer(r.value(:id)) }
  end

  def home_project
    redirect_to :controller => :project, :action => :show, :project => "home:#{@user}"
  end

  def list_my
    @displayed_user.free_cache if discard_cache?
    @iprojects = @displayed_user.involved_projects.each.map {|x| x.name}.uniq.sort
    @ipackages = Hash.new
    pkglist = @displayed_user.involved_packages.each.reject {|x| @iprojects.include?(x.project)}
    pkglist.sort(&@displayed_user.method('packagesorter')).each do |pack|
      @ipackages[pack.project] ||= Array.new
      @ipackages[pack.project] << pack.name if !@ipackages[pack.project].include? pack.name
    end
  end

  def remove_watched_project
    logger.debug "removing watched project '#{params[:project]}' from user '#@user'"
    @user.remove_watched_project(params[:project])
    @user.save
    render :partial => 'watch_list'
  end

  def overwrite_user
    @displayed_user = @user
    user = find_cached(Person, params['user'] ) if params['user']
    @displayed_user = user if user
  end
  private :overwrite_user
end
