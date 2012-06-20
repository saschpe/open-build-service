# vim: sw=2 et

require 'digest/md5'

require 'action_view/helpers/asset_tag_helper.rb'
module ActionView
  module Helpers

    @@rails_root = nil
    def real_public
      return @@rails_root if @@rails_root
      @@rails_root = Pathname.new("#{RAILS_ROOT}/public").realpath
    end

    @@icon_cache = Hash.new
    
    def rewrite_asset_path(_source)
      if @@icon_cache[_source]
        return @@icon_cache[_source]
      end
      new_path = "/vendor/#{CONFIG['theme']}#{_source}"
      if File.exists?("#{RAILS_ROOT}/public#{new_path}")
        source = new_path
      elsif File.exists?("#{RAILS_ROOT}/public#{_source}")
        source = _source
      else
        return super(_source)
      end
      source=Pathname.new("#{RAILS_ROOT}/public#{source}").realpath
      source="/" + Pathname.new(source).relative_path_from(real_public).to_s
      Rails.logger.debug "using themed file: #{_source} -> #{source}"
      source = super(source)
      @@icon_cache[_source] = source
    end

    def compute_asset_host(source)
      if CONFIG['use_static'] 
        if ActionController::Base.relative_url_root
          source = source.slice(ActionController::Base.relative_url_root.length..-1)
        end
        if source =~ %r{^/themes}
          return "https://static.opensuse.org"
        elsif source =~ %r{^/images} or source =~ %r{^/javascripts} or source =~ %r{^/stylesheets}
          return "https://static.opensuse.org/hosts/#{CONFIG['use_static']}"
        end
      end
      super(source)
    end

  end
end

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def logged_in?
    !session[:login].nil?
  end
  
  def user
    if logged_in?
      begin
        @user ||= find_cached(Person, session[:login] )
      rescue Object => e
        logger.error "Cannot load person data for #{session[:login]} in application_helper"
      end
    end
    return @user
  end

  def repo_url(project, repo='' )
    if defined? DOWNLOAD_URL
      "#{DOWNLOAD_URL}/" + project.to_s.gsub(/:/,':/') + "/#{repo}"
    else
      nil
    end
  end

  def get_frontend_url_for( opt={} )
    opt[:host] ||= Object.const_defined?(:EXTERNAL_FRONTEND_HOST) ? EXTERNAL_FRONTEND_HOST : FRONTEND_HOST
    opt[:port] ||= Object.const_defined?(:EXTERNAL_FRONTEND_PORT) ? EXTERNAL_FRONTEND_PORT : FRONTEND_PORT
    opt[:protocol] ||= Object.const_defined?(:EXTERNAL_FRONTEND_PROTOCOL) ? EXTERNAL_FRONTEND_PROTOCOL : FRONTEND_PROTOCOL

    if not opt[:controller]
      logger.error "No controller given for get_frontend_url_for()."
      return
    end

    return "#{opt[:protocol]}://#{opt[:host]}:#{opt[:port]}/#{opt[:controller]}"
  end

  def bugzilla_url(email_list="", desc="")
    return '' if BUGZILLA_HOST.nil?
    assignee = email_list.first if email_list
    if email_list.length > 1
      cc = ("&cc=" + email_list[1..-1].join("&cc=")) if email_list
    end
    URI.escape("#{BUGZILLA_HOST}/enter_bug.cgi?classification=7340&product=openSUSE.org&component=3rd party software&assigned_to=#{assignee}#{cc}&short_desc=#{desc}")
  end

  def get_random_sponsor_image
    sponsors = [
      "/themes/bento/images/sponsors/sponsor_suse.png",
      "/themes/bento/images/sponsors/sponsor_amd.png",
      "/themes/bento/images/sponsors/sponsor_b1-systems.png",
      "/themes/bento/images/sponsors/sponsor_ip-exchange2.png",
      "/themes/bento/images/sponsors/sponsor_heinlein.png"]
    return sponsors[rand(sponsors.size)]
  end

  def image_url(source)
    abs_path = image_path(source)
    unless abs_path =~ /^http/
      abs_path = "#{request.protocol}#{request.host_with_port}#{abs_path}"
    end
    abs_path
  end

  def user_icon(login, size=20)
    return image_tag(url_for(:controller => :home, :action => :icon, :id => login.to_s, :size => size), 
                     :width => size, :height => size)
  end

  def fuzzy_time_string(time)
    diff = Time.now - Time.parse(time)
    return "now" if diff < 60
    return (diff/60).to_i.to_s + " min ago" if diff < 3600
    diff = Integer(diff/3600) # now hours
    return diff.to_s + (diff == 1 ? " hour ago" : " hours ago") if diff < 24
    diff = Integer(diff/24) # now days
    return diff.to_s + (diff == 1 ? " day ago" : " days ago") if diff < 14
    diff_w = Integer(diff/7) # now weeks
    return diff_w.to_s + (diff_w == 1 ? " week ago" : " weeks ago") if diff < 63
    diff_m = Integer(diff/30.5) # roughly months
    return diff_m.to_s + " months ago"
  end

  def status_for( repo, arch, package )
    @statushash[repo][arch][package] || { "package" => package } 
  end

  def format_projectname(prjname, homename)
    splitted = prjname.split(':', 4)
    if splitted[0] == "home"
      if homename and splitted[1] == homename
        if splitted.length == 2
          prjname = "~"
        else
          prjname = "~:" + splitted[-1]
        end
      else
        prjname = "~" + splitted[1] + ":" + splitted[-1]
      end
    end
    prjname
  end

  def status_id_for( repo, arch, package )
    valid_xml_id("id-#{package}_#{repo}_#{arch}")
  end

  def arch_repo_table_cell(repo, arch, packname)
    status = status_for(repo, arch, packname)
    status_id = status_id_for( repo, arch, packname)
    link_title = status['details']
    if status['code']
      code = status['code']
      theclass="status_" + code.gsub(/[- ]/,'_')
    else
      code = ''
      theclass=''
    end

    out = "<td class='#{theclass} buildstatus'>"
    if ["unresolvable", "blocked"].include? code 
      out += link_to code, "#", :title => link_title, :id => status_id
      content_for :ready_function do
        "$('a##{status_id}').click(function() { alert('#{link_title.gsub(/'/, '\\\\\'')}'); return false; });\n"
      end
    elsif ["-","excluded"].include? code
      out += code
    else
      out += link_to code.gsub(/\s/, "&nbsp;"), {:action => :live_build_log,
        :package => packname, :project => @project.to_s, :arch => arch,
        :controller => "package", :repository => repo}, {:title => link_title, :rel => 'nofollow'}
    end 
    out += "</td>"
    return out.html_safe
  end

  
  def repo_status_icon( status )
    icon = case status
    when "published" then "icons/lorry.png"
    when "publishing" then "icons/cog_go.png"
    when "outdated_published" then "icons/lorry_error.png"
    when "outdated_publishing" then "icons/cog_error.png"
    when "unpublished" then "icons/lorry_flatbed.png"
    when "outdated_unpublished" then "icons/lorry_error.png"
    when "building" then "icons/cog.png"
    when "outdated_building" then "icons/cog_error.png"
    when "finished" then "icons/time.png"
    when "outdated_finished" then "icons/time_error.png"
    when "blocked" then "icons/time.png"
    when "outdated_blocked" then "icons/time_error.png"
    when "broken" then "icons/exclamation.png"
    when "outdated_broken" then "icons/exclamation.png"
    when "scheduling" then "icons/cog.png"
    when "outdated_scheduling" then "icons/cog_error.png"
    else "icons/eye.png"
    end

    outdated = nil
    if status =~ /^outdated_/
      status.gsub!( %r{^outdated_}, '' )
      outdated = true
    end
    description = case status
    when "published" then "Repository has been published"
    when "publishing" then "Repository is being created right now"
    when "unpublished" then "Build finished, but repository publishing is disabled"
    when "building" then "Build jobs exists"
    when "finished" then "Build jobs have been processed, new repository is not yet created"
    when "blocked" then "No build possible atm, waiting for jobs in other repositories"
    when "broken" then "The repository setup is broken, build not possible"
    when "scheduling" then "The repository state is being calculated right now"
    else "Unknown state of repository"
    end

    description = "State needs recalculations, former state was: " + description if outdated

    image_tag icon, :size => "16x16", :title => description, :alt => description
  end


  def flag_status(flags, repository, arch)
    image = nil
    flag = nil

    flags.each do |f|

      if f.has_attribute? :repository
        next if f.repository.to_s != repository
      else
        next if repository
      end
      if f.has_attribute? :arch
        next  if f.arch.to_s != arch
      else
        next if arch 
      end

      flag = f
      break
    end

    if flag
      if flag.has_attribute? :explicit
        if flag.element_name == 'disable'
          image = "#{flags.element_name}_disabled_blue.png"
        else
          image = "#{flags.element_name}_enabled_blue.png"
        end
      else
        if flag.element_name == 'disable'
          image = "#{flags.element_name}_disabled_grey.png"
        else
          image = "#{flags.element_name}_enabled_grey.png"
        end
      end

      if @user && @user.is_maintainer?(@project, @package)
        opts = { :project => @project, :repository => repository, :arch => arch, :package => @package, :flag => flags.element_name, :action => :change_flag }
        out = "<div class='flagimage'>" + image_tag(image) + "<div class='hidden flagtoggle'>"
        unless flag.has_attribute? :explicit and flag.element_name == 'disable'
          out += 
            "<div class='nowrap'>" +
            image_tag("#{flags.element_name}_disabled_blue.png", :alt => '0', :size => "24x24") +
            link_to("Explicitly disable", opts.merge({ :cmd => :set_flag, :status => :disable }), {:class => :flag_trigger}) +
            "</div>"
        end
        if flag.element_name == 'disable'
          out += 
            "<div class='nowrap'>" +
            image_tag("#{flags.element_name}_enabled_grey.png", :alt => '1', :size => "24x24") +
            link_to("Take default", opts.merge({ :cmd => :remove_flag }),:class => :flag_trigger) +
            "</div>"
        else
          out += 
            "<div class='nowrap'>" +
            image_tag("#{flags.element_name}_disabled_grey.png", :alt => '0', :size => "24x24") +
            link_to("Take default", opts.merge({ :cmd => :remove_flag }), :class => :flag_trigger)+
            "</div>"
        end if flag.has_attribute? :explicit
        unless flag.has_attribute? :explicit and flag.element_name != 'disable'
          out += 
            "<div class='nowrap'>" +
            image_tag("#{flags.element_name}_enabled_blue.png", :alt => '1', :size => "24x24") +
            link_to("Explicitly enable", opts.merge({ :cmd => :set_flag, :status => :enable }), :class => :flag_trigger) +
            "</div>"
        end
        out += "</div></div>"
        out.html_safe
      else
        image_tag(image)
      end
    else
      ""
    end
  end

  def plural( count, singular, plural)
    count > 1 ? plural : singular
  end

  def valid_xml_id(rawid)
    rawid = '_' + rawid if rawid !~ /^[A-Za-z_]/ # xs:ID elements have to start with character or '_'
    ERB::Util::h(rawid.gsub(/[+&: .\/\~\(\)@]/, '_'))
  end

  def tab(text, opts)
    opts[:package] = @package.to_s if @package
    opts[:project] = @project.to_s
    if @current_action.to_s == opts[:action].to_s and @current_controller.to_s == opts[:controller].to_s
      link = "<li class='selected'>"
    else
      link = "<li>"
    end
    link += link_to(h(text), opts)
    link += "</li>"
    return link.html_safe
  end

  # Shortens a text if it longer than 'length'. 
  def elide(text, length = 20, mode = :middle)
    shortened_text = text.to_s      # make sure it's a String

    return "..." if length <= 3     # corner case

    if text.length > length
      case mode
      when :left                    # shorten at the beginning
        shortened_text = "..." + text[text.length - length + 3 .. text.length]
      when :middle                  # shorten in the middle
        pre = text[0 .. length / 2 - 2]
        offset = 2                  # depends if (shortened) length is even or odd
        offset = 1 if length.odd?
        post = text[text.length - length / 2 + offset .. text.length]
        shortened_text = pre + "..." + post
      when :right                   # shorten at the end
        shortened_text = text[0 .. length - 4 ] + "..."
      end
    end
    return shortened_text
  end

  def elide_two(text1, text2, overall_length = 40, mode = :middle)
    half_length = overall_length / 2
    text1_free = half_length - text1.length
    text1_free = 0 if text1_free < 0
    text2_free = half_length - text2.length
    text2_free = 0 if text2_free < 0
    return [elide(text1, half_length + text2_free, mode), elide(text2, half_length + text1_free, mode)]
  end

  def force_utf8_and_transform_nonprintables(text)
    begin
      new_text = Iconv.iconv('UTF-8//IGNORE//TRANSLIT', 'UTF-8', text)[0]
    rescue
      new_text = 'You tried to display binary garbage, but got this beautiful message instead!'
    end
    # Ged rid of stuff that shouldn't be part of PCDATA:
    new_text.gsub!(/([^a-zA-Z0-9&;<>\/\n \t()])/n) do
      if $1[0].getbyte(0) < 32
        ''
      else
        $1
      end
    end
    return new_text
  end

  def reload_to_remote(opts)
    {:title => "Reload", :url => nil, :update => nil}.merge(opts)

    id = valid_xml_id(opts[:title])
    return link_to_remote(image_tag("arrow_refresh.png", :title => opts[:title], :title => opts[:title], :id => id + "_reload") +
                          image_tag("ajax-loader.gif", :id => id + "_spinner", :class => "hidden"),
                          :url => opts[:url], :update => opts[:update],
                          :loading => "$('##{id}_spinner').show(); $('##{id}_reload').hide()",
                          :complete => "$('##{id}_spinner').hide(); $('##{id}_reload').show()")
  end

  # Same as redirect_to(:back) if there is a valid HTTP referer, otherwise redirect_to()
  def redirect_back_or_to(options = {}, response_status = {})
    if request.env["HTTP_REFERER"]
      redirect_to(:back)
    else
      redirect_to(options, response_status)
    end
  end

  def description_wrapper(description)
    unless description.blank?
      content_tag(:pre, description, :id => "description", :class => "plain")
    else
      content_tag(:p, :id => "description") do
        content_tag(:i, "No description set")
      end
    end
  end

  def request_state_color(state)
    case state.to_s
    when 'new', 'superseded' then return 'green'
    when 'declined' then return 'maroon'
    when 'review' then return 'olive'
    when 'revoked' then return 'gray'
    else return ''
    end
  end

end

