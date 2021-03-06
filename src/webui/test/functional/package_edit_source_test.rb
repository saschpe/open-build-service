# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"        

class PackageEditSourcesTest < ActionDispatch::IntegrationTest
  include ApplicationHelper
  include ActionView::Helpers::JavaScriptHelper

  def setup
    @package = "TestPack"
    @project = "home:Iggy"
    super

    login_Iggy
    visit package_show_path(:project => @project, :package => @package)
  end

  def text_path(name)
    File.expand_path( Rails.root.join("test/texts/#{name}") )
  end

  def open_file file
    find(:css, "tr##{valid_xml_id('file-' + file)} td:first-child a").click
    page.must_have_text "File #{file} of Package #{@package}"
  end

  def open_add_file
    click_link('Add file')
    page.must_have_text "Add File to"
  end

  def add_file file
    file[:expect]      ||= :success
    file[:name]        ||= ""
    file[:upload_from] ||= :local_file
    file[:upload_path] ||= ""

    assert [:local_file, :remote_url].include? file[:upload_from]

    fill_in "filename", with: file[:name]

    if file[:upload_from] == :local_file then
      find(:id, "file_type").select("local file")
      begin
        page.attach_file("file", file[:upload_path]) unless file[:upload_path].blank?
      rescue Capybara::FileNotFound
        if file[:expect] != :invalid_upload_path
          raise "file was not found, but expect was #{file[:expect]}"
        else
          return
        end
      end
    else
      find(:id, "file_type").select("remote URL")
      fill_in("file_url", with: file[:upload_path]) if file[:upload_path]
    end
    click_button("Save changes")

    # get file's name from upload path in case it wasn't specified caller
    file[:name] = File.basename(file[:upload_path]) if file[:name] == ""

    if file[:expect] == :success
      flash_message.must_equal "The file #{file[:name]} has been added."
      flash_message_type.must_equal :info
      assert find(:css, "#files_table tr#file-#{valid_xml_id(file[:name])}")
      # TODO: Check that new file is in the list
    elsif file[:expect] == :no_path_given
      assert_equal :alert, flash_message_type
      assert_equal flash_message, "No file or URI given."
    elsif file[:expect] == :invalid_upload_path
      flash_message_type.must_equal :alert
      page.must_have_text "Add File to"
    elsif file[:expect] == :no_permission
      flash_message_type.must_equal :alert
      page.must_have_text "Add File to"
    elsif file[:expect] == :download_failed
      # the _service file is added, but the download fails
      fm = flash_messages
      fm.count.must_equal 2
      fm[0].must_equal "The file #{file[:name]} has been added."
      assert fm[1].include?("service download_url failed"), "expected '#{fm[1]}' to include 'Download failed'"
    else
      raise "Invalid value for argument expect."
    end
  end

  # ============================================================================
  #
  def edit_file new_content
    # new edit page does not allow comments
    
    savebutton = find(:css, ".buttons.save")
    page.must_have_selector(".buttons.save.inactive")
    
    # is it all rendered?
    page.must_have_selector(".CodeMirror-lines")

    # codemirror is not really test friendly, so just brute force it - we basically
    # want to test the load and save work flow not the codemirror library
    page.execute_script("editors[0].setValue('#{escape_javascript(new_content)}');")
    
    # wait for it to be active
    page.wont_have_selector(".buttons.save.inactive")
    assert !savebutton["class"].split(" ").include?("inactive")
    savebutton.click
    page.must_have_selector(".buttons.save.inactive")
    assert savebutton["class"].split(" ").include? "inactive"

    #flash_message.must_equal "Successfully saved file #{@file}"
    #flash_message_type.must_equal :info

  end
  
  test "erase_file_content" do
    open_file "myfile"
    edit_file ""
  end
  
  test "edit_empty_file" do
    open_file "TestPack.spec"
    edit_file File.read( text_path( "SourceFile.cc") )
  end

  
  test "add_new_source_file_to_home_project_package" do
    
    open_add_file
    add_file :name => "HomeSourceFile1"
  end


  test "add_source_file_from_local_file" do
    
    open_add_file
    add_file(upload_from: :local_file,
             upload_path: text_path("SourceFile.cc"))
  end
  
    
  test "add_source_file_from_local_file_override_name" do
    
    open_add_file
    add_file(
      name: "HomeSourceFile3",
      upload_from: :local_file,
      upload_path: text_path( 'SourceFile.cc' ))
  end
  
  
  test "add_source_file_from_empty_local_file" do
    
    open_add_file
    add_file(
      upload_from: :local_file,
      upload_path: text_path("EmptySource.c"))
  end
  
  test "add_source_file_with_invalid_name" do
  
    open_add_file
    add_file(
      :name => "\/\/ invalid name",
      :upload_from => :local_file,
      :expect => :invalid_upload_path)
  end


  test "add_source_file_all_fields_empty" do
  
    open_add_file
    add_file(
      :name => "",
      :upload_path => "",
      :expect => :invalid_upload_path)
  end

end
