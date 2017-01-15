require 'rails_helper'

RSpec.describe FakeStudent do

  let!(:school) { FactoryGirl.create(:school) }
  let!(:homeroom) { FactoryGirl.create(:homeroom, grade: '5') }
  before { FactoryGirl.create(:educator, :admin) }

  let(:student) { described_class.new(school, homeroom).student }

  it 'sets student name' do
    expect(student.first_name).not_to be_nil
    expect(student.last_name).not_to be_nil
  end

  it 'sets student language attributes' do
    expect(student.limited_english_proficiency).not_to be_nil
    expect(student.home_language).not_to be_nil
  end

  it 'adds student assessments' do
    expect(student.student_assessments).not_to be_empty
  end

  context 'd is 1 always' do
    let(:d) { {1 => 1.0} }
    it 'samples from a distribution correctly' do
      expect(DemoDataUtil.sample_from_distribution d).to eq 1
    end
  end

end
