class WatchedProject < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'bs_user_id'
  belongs_to :db_project
end
