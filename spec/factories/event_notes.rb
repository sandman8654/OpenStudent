FactoryGirl.define do

  factory :event_note do
    recorded_at DateTime.new(2016, 4, 9)
    association :educator
    association :student
    event_note_type { EventNoteType.first }
    is_restricted false
  end

end
