class Tardy < ActiveRecord::Base
  belongs_to :student_school_year
  validates_presence_of :student_school_year, :occurred_at
end
