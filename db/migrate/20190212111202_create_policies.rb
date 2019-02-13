class CreatePolicies < ActiveRecord::Migration
  def change
    create_table :policies do |t|
      t.string :name
      t.string :version
      t.binary :schema, limit: 16.megabytes
      t.references :account, index: true, foreign_key: { on_delete: :cascade }, limit: 8
      t.integer  :tenant_id, limit: 8
      t.timestamps
    end
  end
end
