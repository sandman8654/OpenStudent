class AddRecentAttendanceEventsCountsToStudents < ActiveRecord::Migration
  def change
    add_column :students, :absences_count_most_recent_school_year, :integer
    add_column :students, :tardies_count_most_recent_school_year, :integer
  end
end
