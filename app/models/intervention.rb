class Intervention < ActiveRecord::Base
  belongs_to :student
  belongs_to :educator
  belongs_to :intervention_type
  belongs_to :school_year
  belongs_to :student_school_year
  before_save :assign_to_school_year
  after_create :assign_to_student_school_year
  validates :student, :intervention_type, :start_date, presence: true
  validate :end_date_cannot_come_before_start_date

  def name
    custom_intervention_name || intervention_type.try(:name)
  end

  ## VALIDATIONS ##

  def end_date_cannot_come_before_start_date
    if end_date.present?
      if end_date < start_date
        errors.add(:end_date, "can't be before start date")
      end
    end
  end

  ## SCHOOL YEARS ##

  def assign_to_school_year
    self.school_year = DateToSchoolYear.new(start_date).convert
  end

  def assign_to_student_school_year
    self.student_school_year = StudentSchoolYear.where({
      student_id: student.id, school_year_id: school_year.id
    }).first_or_create!
    save
  end

  ## CHARTS ##

  def to_highcharts
    {
      start_date: { year: start_date.year, month: start_date.month, day: start_date.day },
      end_date: { year: end_date.year, month: end_date.month, day: end_date.day },
      name: name
    }
  end

  ## SCOPES ##

  def self.with_start_and_end_dates
    where.not(start_date: nil).where.not(end_date: nil)
  end

end
