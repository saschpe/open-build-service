class WatchlistUseProjectIds < ActiveRecord::Migration

  def self.up
    add_column :watched_projects, :db_project_id, :integer, :after => :bs_user_id, :null => false
    # Convert names to db_project ids
    WatchedProject.all.each do |wp|
      prj = DbProject.find_by_name(wp.name)
      if prj
        wp.db_project_id = prj.id
        wp.save
      end
    end
    remove_column :watched_projects, :name
  end

  def self.down
    add_column :watched_projects, :name, :string, :after => :bs_user_id, :null => false
    # Convert db_project ids to names
    WatchedProject.all.each do |wp|
      prj = DbProject.find(wp.db_project_id)
      if prj
        wp.name = prj.name
        wp.save
      end
    end
    remove_column :watched_projects, :db_project_id
  end

end
