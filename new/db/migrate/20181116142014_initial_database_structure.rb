class InitialDatabaseStructure < ActiveRecord::Migration[5.2]
  def change
    create_table :deployments do |t|
      t.string :name, null: false
      t.string :template, null: false
      t.string :platform, null: false

      t.timestamps null: false
    end

    create_table :nodes do |t|
      t.string :name, null: false

      t.timestamps null: false
    end

    create_table :outputs do |t|
      t.references :deployment,
        foreign_key: true,
        null: false,
        # Here and below, specify this for all foreign keys so whenever a
        # Deployment is deleted all related records will be too.
        on_delete: :cascade

      t.references :node,
        foreign_key: true,
        null: true,
        on_delete: :cascade

      t.string :name, null: false
      t.string :value, null: false

      t.timestamps null: false
    end
  end
end
