class CreateEventNoteRevisions < ActiveRecord::Migration
  def change
    create_table :event_note_revisions do |t|
      t.integer :student_id
      t.integer :educator_id
      t.integer :event_note_type_id
      t.text :text
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :event_note_id
      t.integer :version

      t.timestamps
    end
  end
end
