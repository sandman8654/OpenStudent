class AddRestrictedAccessFieldsToEducators < ActiveRecord::Migration
  def change
    add_column :educators, :restricted_to_sped_students, :boolean, default: false
    add_column :educators, :restricted_to_english_language_learners, :boolean, default: false
  end
end
