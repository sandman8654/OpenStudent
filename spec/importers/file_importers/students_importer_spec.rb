require 'rails_helper'

RSpec.describe StudentsImporter do

  describe '#import_row' do

    context 'good data' do
      let(:file) { File.open("#{Rails.root}/spec/fixtures/fake_students_export.txt") }
      let(:transformer) { CsvTransformer.new }
      let(:csv) { transformer.transform(file) }

      let(:importer) { described_class.new }          # We don't pass in args

      let(:import) {
        csv.each { |row| importer.import_row(row) }   # No school filter here because
      }                                               # we are calling 'import' directly
                                                      # on each row

      let!(:high_school) { School.create(local_id: 'SHS') }
      let!(:healey) { School.create(local_id: 'HEA') }
      let!(:brown) { School.create(local_id: 'BRN') }

      context 'no existing students in database' do

        it 'imports students' do
          expect { import }.to change { Student.count }.by 2
        end

        it 'imports student data correctly' do
          import

          first_student = Student.find_by_state_id('1000000000')
          expect(first_student.reload.school).to eq healey
          expect(first_student.program_assigned).to eq 'Sp Ed'
          expect(first_student.limited_english_proficiency).to eq 'Fluent'
          expect(first_student.student_address).to eq '155 9th St, San Francisco, CA'
          expect(first_student.registration_date).to eq DateTime.new(2008, 2, 20)
          expect(first_student.free_reduced_lunch).to eq 'Not Eligible'
          expect(first_student.date_of_birth).to eq DateTime.new(1998, 7, 15)
        end

      end

      context 'student in database who has since graduated on to high school' do
        let!(:graduating_student) {
          Student.create!(local_id: '101', school: healey, grade: '8')   # Old data
        }

        it 'imports students' do
          expect { import }.to change { Student.count }.by 2
        end

        it 'updates the student\'s data correctly' do
          import

          expect(graduating_student.reload.school).to eq nil
          expect(graduating_student.grade).to eq 'HS'
          expect(graduating_student.enrollment_status).to eq 'High School'
        end

      end

    end

    context 'bad data' do
      context 'missing state id' do
        let(:row) { { state_id: nil, full_name: 'Hoag, George', home_language: 'English', grade: '1', homeroom: '101' } }
        it 'raises an error' do
          expect{ described_class.new.import_row(row) }.to raise_error ActiveRecord::RecordInvalid
        end
      end
    end

  end

  describe '#assign_student_to_homeroom' do

    context 'student already has a homeroom' do
      let!(:school) { FactoryGirl.create(:school) }
      let!(:student) { FactoryGirl.create(:student_with_homeroom, school: school) }
      let!(:new_homeroom) { FactoryGirl.create(:homeroom, school: school) }

      it 'assigns the student to the homeroom' do
        described_class.new.assign_student_to_homeroom(student, new_homeroom.name)
        expect(student.reload.homeroom).to eq(new_homeroom)
      end
    end

    context 'student does not have a homeroom' do
      let!(:student) { FactoryGirl.create(:student) }
      let!(:new_homeroom_name) { '152I' }
      it 'creates a new homeroom' do
        expect {
          described_class.new.assign_student_to_homeroom(student, new_homeroom_name)
        }.to change(Homeroom, :count).by(1)
      end
      it 'assigns the student to the homeroom' do
        described_class.new.assign_student_to_homeroom(student, new_homeroom_name)
        new_homeroom = Homeroom.find_by_name(new_homeroom_name)
        expect(student.homeroom_id).to eq(new_homeroom.id)
      end
    end

    context 'student is inactive' do
      let!(:student) { FactoryGirl.create(:student, enrollment_status: 'Inactive') }
      let!(:new_homeroom_name) { '152K' }

      it 'does not create a new homeroom' do
        expect {
          described_class.new.assign_student_to_homeroom(student, new_homeroom_name)
        }.to change(Homeroom, :count).by(0)
      end

    end

  end
end
