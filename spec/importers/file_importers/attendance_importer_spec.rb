require 'rails_helper'

RSpec.describe AttendanceImporter do

  let(:importer) { Importer.new(current_file_importer: described_class.new) }

  describe '#import_row' do

    context 'one row for one student on one date' do

      let(:student) { FactoryGirl.create(:student, local_id: '1') }
      let(:date) { DateTime.parse('2005-09-16') }
      let(:school_year) { DateToSchoolYear.new(date).convert }
      let!(:student_school_year) { StudentSchoolYear.create(student: student, school_year: school_year) }

      context 'row with absence' do
        let(:row) { { event_date: date, local_id: '1', absence: '1', tardy: '0' } }

        it 'creates an absence' do
          expect { described_class.new.import_row(row) }.to change { Absence.count }.by 1
        end

        it 'creates only 1 absence if run twice' do
          expect {
            described_class.new.import_row(row)
            described_class.new.import_row(row)
          }.to change { Absence.count }.by 1
        end

        it 'increments the student school year absences by 1' do
          expect {
            described_class.new.import_row(row)
          }.to change { StudentSchoolYear.last.absences.size }.by 1
        end

        it 'does not increment the student school year tardies' do
          expect {
            described_class.new.import_row(row)
          }.to change { StudentSchoolYear.last.tardies.size }.by 0
        end
      end
    end

    context 'multiple rows for different students on the same date' do

      let(:edwin) { FactoryGirl.create(:student, local_id: '1', first_name: 'Edwin') }
      let(:kristen) { FactoryGirl.create(:student, local_id: '2', first_name: 'Kristen') }
      let(:date) { DateTime.parse('2005-09-16') }
      let(:school_year) { DateToSchoolYear.new(date).convert }

      before do
        StudentSchoolYear.create(student: edwin, school_year: school_year)
        StudentSchoolYear.create(student: kristen, school_year: school_year)
      end

      let(:row_for_edwin) { { event_date: date, local_id: '1', absence: '1', tardy: '0' } }
      let(:row_for_kristen) { { event_date: date, local_id: '2', absence: '1', tardy: '0' } }

      it 'creates an absence for each student' do
        expect {
          described_class.new.import_row(row_for_edwin)
          described_class.new.import_row(row_for_kristen)
        }.to change { Absence.count }.by 2
      end

    end

    context 'multiple rows for same student on same date' do
      let(:student) { FactoryGirl.create(:student, local_id: '1') }
      let(:date) { DateTime.parse('2005-09-16') }
      let(:school_year) { DateToSchoolYear.new(date).convert }
      let!(:student_school_year) { StudentSchoolYear.create(student: student, school_year: school_year) }

      let(:first_row) { { event_date: date, local_id: '1', absence: '1', tardy: '0' } }
      let(:second_row) { { event_date: date, local_id: '1', absence: '1', tardy: '0' } }

      it 'creates an absence' do
        expect {
          described_class.new.import_row(first_row)
          described_class.new.import_row(second_row)
        }.to change { Absence.count }.by 1
      end

    end

    context 'multiple rows for same student on different dates' do
      let(:student) { FactoryGirl.create(:student, local_id: '1') }
      let(:date) { DateTime.parse('2005-09-16') }
      let(:school_year) { DateToSchoolYear.new(date).convert }
      let!(:student_school_year) { StudentSchoolYear.create(student: student, school_year: school_year) }

      let(:first_row) { { event_date: date, local_id: '1', absence: '1', tardy: '0' } }
      let(:second_row) { { event_date: date + 1.day, local_id: '1', absence: '1', tardy: '0' } }
      let(:third_row) { { event_date: date + 2.days, local_id: '1', absence: '1', tardy: '0' } }
      let(:fourth_row) { { event_date: date + 3.days, local_id: '1', absence: '1', tardy: '0' } }

      it 'creates multiple absences' do
        importer = described_class.new
        expect {
          importer.import_row(first_row)
          importer.import_row(second_row)
          importer.import_row(third_row)
          importer.import_row(fourth_row)
        }.to change { Absence.count }.by 4
      end

    end

  end
end
