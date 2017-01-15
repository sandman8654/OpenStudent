require 'rails_helper'

describe HomeroomsController, :type => :controller do
  let!(:school) { FactoryGirl.create(:school) }

  describe '#show' do
    def make_request(slug = nil)
      request.env['HTTPS'] = 'on'
      get :show, id: slug
    end

    context 'educator with homeroom logged in' do
      let!(:educator) { FactoryGirl.create(:educator, school: school) }
      let!(:homeroom) { FactoryGirl.create(:homeroom, educator: educator, grade: "5", school: school) }
      before { sign_in(educator) }

      context 'homeroom params' do

        context 'garbage params' do
          it 'does not raise an error' do
            expect { make_request('garbage homeroom ids rule') }.not_to raise_error
          end
          it 'redirects to educator\'s homeroom' do
            make_request('garbage homeroom ids rule')
            expect(response).to redirect_to(homeroom_path(educator.homeroom))
          end
        end

        context 'params for homeroom belonging to educator' do
          it 'is successful' do
            make_request(educator.homeroom.slug)
            expect(response.status).to eq 200
          end
          it 'assigns correct homerooms to drop-down' do
            make_request(educator.homeroom.slug)
            expect(assigns(:homerooms_by_name)).to eq([educator.homeroom])
          end

          context 'when there are no students' do
            it 'assigns rows to empty' do
              make_request(educator.homeroom.slug)
              expect(assigns(:rows)).to be_empty
            end
          end

          context 'when there are students' do
            let!(:first_student) { FactoryGirl.create(:student, :registered_last_year, homeroom: educator.homeroom) }
            let!(:second_student) { FactoryGirl.create(:student, :registered_last_year, homeroom: educator.homeroom) }
            let!(:third_student) { FactoryGirl.create(:student, :registered_last_year) }

            before { Student.update_student_school_years }
            before { Student.update_risk_levels }

            it 'assigns rows to a non-empty array' do
              make_request(educator.homeroom.slug)
              expect(assigns(:rows).size).to eq 2
              expect(assigns(:rows)[0]).to include Student.all.second.as_json
              expect(assigns(:rows)[1]).to include Student.all.first.as_json
            end
          end

          context 'homeroom grade level above 3' do
            before { Homeroom.first.update(grade: '4') }
            it 'sets initial cookies to show mcas columns on page load' do
              make_request(educator.homeroom.slug)
              expect(response.cookies['columns_selected']).to include 'mcas_math'
              expect(response.cookies['columns_selected']).to include 'mcas_ela'
            end
          end

          context 'homeroom grade level below 3' do
            before { Homeroom.first.update(grade: 'KF') }
            it 'sets initial cookies to not show mcas columns on page load' do
              make_request(educator.homeroom.slug)
              expect(response.cookies['columns_selected']).not_to include 'mcas_math'
              expect(response.cookies['columns_selected']).not_to include 'mcas_ela'
            end
          end

        end

        context 'homeroom does not belong to educator' do

          context 'homeroom is grade level as educator\'s and same school' do
            let(:another_homeroom) { FactoryGirl.create(:homeroom, grade: '5', school: school) }
            it 'is successful' do
              make_request(another_homeroom.slug)
              expect(response.status).to eq 200
            end
          end

          context 'homeroom is grade level as educator\'s -- but different school!' do
            let(:another_homeroom) { FactoryGirl.create(:homeroom, grade: '5', school: FactoryGirl.create(:school)) }
            it 'redirects' do
              make_request(another_homeroom.slug)
              expect(response.status).to eq 302
            end
          end

          context 'homeroom is different grade level from educator\'s' do
            let(:yet_another_homeroom) { FactoryGirl.create(:homeroom, school: school) }
            it 'redirects to educator\'s homeroom' do
              make_request(yet_another_homeroom.slug)
              expect(response).to redirect_to(homeroom_path(educator.homeroom))
            end
          end

          context 'educator has appropriate grade level access' do
            let(:educator) { FactoryGirl.create(:educator, grade_level_access: ['5'], school: school) }
            let(:homeroom) { FactoryGirl.create(:homeroom, grade: '5', school: school) }

            it 'is successful' do
              make_request(homeroom.slug)
              expect(response.status).to eq 200
            end
          end

          context 'educator does not have correct grade level access, but has access to a different grade' do
            let(:school) { FactoryGirl.create(:school) }
            before { FactoryGirl.create(:student, school: school) }
            let(:educator) { FactoryGirl.create(:educator, grade_level_access: ['3'], school: school )}
            let(:homeroom) { FactoryGirl.create(:homeroom, grade: '5', school: school) }

            it 'redirects' do
              make_request(homeroom.slug)
              expect(response).to redirect_to(school_path(school))
            end
          end

        end

      end

      context 'no homeroom params' do
        it 'raises an error' do
          expect { make_request }.to raise_error ActionController::UrlGenerationError
        end
      end

    end

    context 'admin educator logged in' do
      let(:admin_educator) { FactoryGirl.create(:educator, :admin, school: school) }
      before { sign_in(admin_educator) }

      context 'no homeroom params' do
        it 'raises an error' do
          expect { make_request }.to raise_error ActionController::UrlGenerationError
        end
      end

      context 'homeroom params' do
        context 'good homeroom params' do
          let(:homeroom) { FactoryGirl.create(:homeroom, grade: '5', school: school) }
          it 'is successful' do
            make_request(homeroom.slug)
            expect(response.status).to eq 200
          end
          it 'assigns correct homerooms to drop-down' do
            make_request(homeroom.slug)
            expect(assigns(:homerooms_by_name)).to eq(Homeroom.order(:name))
          end
        end

        context 'garbage homeroom params' do
          before { FactoryGirl.create(:student, school: school) }
          it 'redirects to overview page' do
            make_request('garbage homeroom ids rule')
            expect(response).to redirect_to(school_url(school))
          end
        end

      end
    end

    context 'educator without schoolwide access logged in' do
      before { sign_in(FactoryGirl.create(:educator)) }

      context 'no homeroom params' do
        it 'raises an error' do
          expect { make_request }.to raise_error ActionController::UrlGenerationError
        end
      end

      context 'homeroom params' do
        let!(:homeroom) { FactoryGirl.create(:homeroom) }
        it 'redirects to no-homeroom error page' do
          make_request(homeroom.slug)
          expect(response).to redirect_to(no_homeroom_url)
        end
      end
    end

    context 'educator not logged in' do
      let!(:educator) { FactoryGirl.create(:educator, school: school) }
      let!(:homeroom) { FactoryGirl.create(:homeroom, educator: educator, grade: "5", school: school) }

      it 'redirects to sign in page' do
        make_request(educator.homeroom.slug)
        expect(response).to redirect_to(new_educator_session_path)
      end
    end

  end
end
