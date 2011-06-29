class CreateDistributions < ActiveRecord::Migration
  def self.up
    create_table :distributions, :primary_key => :id do |t|
      t.string :id, :null => false
      t.string :vendor, :null => false
      t.string :version, :null => false
      t.string :name, :null => false
      t.string :link
    end

    create_table :distribution_icons do |t|
      t.string :url, :null => false
      t.integer :width, :null => false
      t.integer :height, :null => false
    end

    # Create JOIN-table
    create_table :distribution_icons_distributions do |t|
      t.integer :distribution_id
      t.integer :distribution_icon_id
    end
  end

  def self.down
    drop_table :distribution_icons_distributions
    drop_table :distribution_icons
    drop_table :distributions
  end
end
