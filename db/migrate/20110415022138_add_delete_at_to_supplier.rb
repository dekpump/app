class AddDeleteAtToSupplier < ActiveRecord::Migration
  def self.up
    change_table :suppliers do |t|
      t.datetime :deleted_at
    end
  end

  def self.down
    change_table :suppliers do |t|
      t.remove :deleted_at
    end
  end
end
