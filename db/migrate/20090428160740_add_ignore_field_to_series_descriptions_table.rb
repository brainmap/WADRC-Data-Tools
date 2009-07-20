class AddIgnoreFieldToSeriesDescriptionsTable < ActiveRecord::Migration
    def self.up
      add_column :series_descriptions, :ignore, :text, :default => "Don't Ignore"
    end

    def self.down
      remove_column :series_descriptions, :ignore
    end
  end
