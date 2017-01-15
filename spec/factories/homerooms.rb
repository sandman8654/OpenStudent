FactoryGirl.define do

  sequence(:name) { |n| n.to_s }

  trait :named_hea_100 do
    name "HEA 100"
  end

  factory :homeroom do
    name { FactoryGirl.generate(:name) }
    association :school

    factory :homeroom_with_student do
      after(:create) do |homeroom|
        homeroom.students << FactoryGirl.create(:student, :with_risk_level, :registered_last_year)
      end
    end

    factory :homeroom_with_second_grader do
      after(:create) do |homeroom|
        homeroom.students << FactoryGirl.create(:second_grade_student, :with_risk_level, :registered_last_year)
      end
    end

    factory :homeroom_with_pre_k_student do
      after(:create) do |homeroom|
        homeroom.students << FactoryGirl.create(:pre_k_student, :with_risk_level, :registered_last_year)
      end
    end

  end
end
