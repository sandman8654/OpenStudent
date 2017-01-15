class CreateServiceTypes < ActiveRecord::Migration
  def change
    create_table :service_types do |t|
      t.string :name

      t.timestamps
    end

    ServiceType.seed_somerville_service_types
  end
end
