class AddDefaultValueToCanViewRestrictedNotes < ActiveRecord::Migration
  def up
    change_column :educators, :can_view_restricted_notes, :boolean, :default => false
  end

  def down
    change_column :educators, :can_view_restricted_notes, :boolean, :default => nil
  end
end
