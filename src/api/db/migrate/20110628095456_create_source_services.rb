class CreateSourceServices < ActiveRecord::Migration
  def self.up
    create_table :source_services do |t|
      t.string :name
      t.string :summary
      t.string :description
    end

    create_table :source_service_parameters do |t|
      t.integer :source_service_id
      t.string :name
      t.string :description
      t.boolean :required, :default => false
    end

    create_table :source_service_parameter_choices do |t|
      t.integer :source_service_parameter_id
      t.string :value
    end
  end

  def self.down
    drop_table :source_service_parameter_choices
    drop_table :source_service_parameters
    drop_table :source_services
  end
end
