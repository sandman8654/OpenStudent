class FakeStarMathResultGenerator

  def initialize(student, options = {})
    @student = student
    @test_date = options[:start_date] || DateTime.new(2010, 9, 1)
    @star_period_days = options[:star_period_days] || 90
    @math_percentile = rand(10..99)
  end

  def star_math_assessment
    @assessment ||= Assessment.find_by_family_and_subject('STAR', 'Mathematics')
  end

  def next
    @math_percentile += rand(-15..15)
    @math_percentile = [0, @math_percentile, 100].sort[1]
    @test_date += @star_period_days + rand(-10..10)  # days

    return {
      assessment: star_math_assessment,
      date_taken: @test_date,
      percentile_rank: @math_percentile,
      student_id: @student.id
    }
  end
end
