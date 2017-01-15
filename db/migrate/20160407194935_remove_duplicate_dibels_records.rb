class RemoveDuplicateDibelsRecords < ActiveRecord::Migration
  def change
    dibels = Assessment.find_by_family('DIBELS')
    if dibels.present?
      dibels.student_assessments.find_each do |dibels_record|
        dibels_record.destroy if dibels_record.invalid?
      end
    end
  end
end
