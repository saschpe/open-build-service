require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class WatchedProjectTest < ActiveSupport::TestCase
  fixtures :all

  def setup
  end

  def test_watchlist_cleaned_after_project_removal
    tmp_prj = DbProject.create(:name => 'no:use:for:a:name')
    user_ids = User.all(:limit => 5).map{|u|u.id} # Roundup some users to watch tmp_prj
    user_ids.each do |uid|
      WatchedProject.create(:bs_user_id => uid, :db_project_id => tmp_prj.id)
    end

    tmp_id = tmp_prj.id
    assert_equal WatchedProject.find_all_by_db_project_id(tmp_id).length, user_ids.length
    tmp_prj.destroy
    assert_equal WatchedProject.find_all_by_db_project_id(tmp_id).length, 0
  end

  def test_watchlist_cleaned_after_user_removal
    tmp_user = User.create(:login => 'watcher', :email => 'foo@example.com', :password => 'watcher', :password_confirmation => 'watcher')
    db_project_ids = DbProject.all(:limit => 5).map{|p|p.id} # Get some projects to watch
    db_project_ids.each do |db_project_id|
      WatchedProject.create(:bs_user_id => tmp_user.id, :db_project_id => db_project_id)
    end

    tmp_uid = tmp_user.id
    assert_equal WatchedProject.find_all_by_bs_user_id(tmp_uid).length, db_project_ids.length
    tmp_user.destroy
    assert_equal WatchedProject.find_all_by_bs_user_id(tmp_uid).length, 0
  end

end
