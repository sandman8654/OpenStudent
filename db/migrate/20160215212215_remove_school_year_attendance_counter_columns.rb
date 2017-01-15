class RemoveSchoolYearAttendanceCounterColumns < ActiveRecord::Migration
  def change
    remove_column :student_school_years, :tardies_count
    remove_column :student_school_years, :absences_count
    remove_column :student_school_years, :discipline_incidents_count
  end
end
