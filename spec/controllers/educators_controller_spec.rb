require 'rails_helper'

describe EducatorsController, :type => :controller do
  describe '#homepage' do
    def make_request
      request.env['HTTPS'] = 'on'
      get :homepage
    end

    before { sign_in(educator) }

    context 'non admin' do

      context 'with homeroom' do
        let!(:educator) { FactoryGirl.create(:educator_with_homeroom) }
        it 'redirects to default homeroom' do
          make_request
          expect(response).to redirect_to(homeroom_url(educator.homeroom))
        end
      end

      context 'without homeroom' do
        let!(:educator) { FactoryGirl.create(:educator) }
        let!(:homeroom) { FactoryGirl.create(:homeroom) }   # Not associated with educator
        it 'redirects to no homeroom assigned page' do
          make_request
          expect(response).to redirect_to(no_homeroom_url)
        end
      end
    end

    context 'schoolwide access' do

      context 'educator assigned to school' do
        let!(:school) { FactoryGirl.create(:school) }
        let(:educator) { FactoryGirl.create(:educator, :admin, school: school) }
        it 'redirects to the correct school' do
          make_request
          expect(response).to redirect_to(school_url(school))
        end
      end

      context 'educator not assigned to school' do
        let(:educator) { FactoryGirl.create(:educator, :admin) }
        let!(:school) { FactoryGirl.create(:school) }
        before { FactoryGirl.create(:student, school: school) }
        let!(:another_school) { FactoryGirl.create(:school) }
        it 'redirects to first school page' do
          make_request
          expect(response).to redirect_to(school_url(School.first))
        end
      end
    end

    context 'districtwide access' do
      let(:educator) { FactoryGirl.create(:educator, districtwide_access: true) }
      it 'redirects to districtwide homepage' do
        make_request
        expect(response).to redirect_to(educators_districtwide_url)
      end
    end
  end

  describe '#districtwide_admin_homepage' do
    def make_request
      request.env['HTTPS'] = 'on'
      get :districtwide_admin_homepage
    end

    context 'educator signed in' do

      before { sign_in(educator) }

      context 'educator w districtwide access' do
        let(:educator) { FactoryGirl.create(:educator, districtwide_access: true) }
        it 'can access the page' do
          make_request
          expect(response).to be_success
        end
      end

      context 'educator w/o districtwide access' do
        let(:educator) { FactoryGirl.create(:educator) }
        it 'cannot access the page; gets redirected' do
          make_request
          expect(response).to redirect_to(not_authorized_url)
        end
      end
    end

    context 'not signed in' do
      it 'redirects' do
        make_request
        expect(response).to redirect_to(new_educator_session_url)
      end
    end

  end

  describe '#bulk_services_upload' do
    def make_request
      request.env['HTTPS'] = 'on'
      get :bulk_services_upload
    end

    context 'educator signed in' do

      before { sign_in(educator) }

      context 'educator w districtwide access' do
        let(:educator) { FactoryGirl.create(:educator, districtwide_access: true) }
        it 'can access the page' do
          make_request
          expect(response).to be_success
        end
      end

      context 'educator w/o districtwide access' do
        let(:educator) { FactoryGirl.create(:educator) }
        it 'cannot access the page; gets redirected' do
          make_request
          expect(response).to redirect_to(not_authorized_url)
        end
      end
    end

    context 'not signed in' do
      it 'redirects' do
        make_request
        expect(response).to redirect_to(new_educator_session_url)
      end
    end

  end

  describe '#names_for_dropdown' do
    def make_request(student)
      request.env['HTTPS'] = 'on'
      request.env["devise.mapping"] = Devise.mappings[:educator]
      get :names_for_dropdown, format: :json, id: student.id
    end

    context 'authorized' do
      let(:json) { JSON.parse!(response.body) }

      before(:each) do
        sign_in FactoryGirl.create(:educator)
        make_request(student)
      end

      context 'student has no school' do
        let(:student) { FactoryGirl.create(:student) }
        it 'returns an empty array' do
          expect(json).to eq []
        end
      end

      context 'student has school' do
        let(:student) { FactoryGirl.create(:student, school: school) }

        context 'educators at school' do
          let(:school) { FactoryGirl.create(:healey, :with_educator) }
          it 'returns array of their names' do
            expect(json).to eq ['Stephenson, Neal']
          end
        end

        context 'educators providing services' do
          let(:school) { FactoryGirl.create(:healey) }
          let!(:service) {
            FactoryGirl.create(:service, provided_by_educator_name: 'Butler, Octavia')
          }

          it 'returns array of their names' do
            make_request(student)
            expect(json).to eq ['Butler, Octavia']
          end
        end

        context 'educators at school and providing services' do
          let(:school) { FactoryGirl.create(:healey, :with_educator) }
          let!(:service) {
            FactoryGirl.create(:service, provided_by_educator_name: 'Butler, Octavia')
          }

          it 'returns names of both, sorted alphabetically' do
            make_request(student)
            expect(json).to eq ['Butler, Octavia', 'Stephenson, Neal']
          end

          context 'search for "o"' do
            it 'returns Octavia' do
              get :names_for_dropdown, format: :json, id: student.id, term: 'o'
              expect(json).to eq ['Butler, Octavia']
            end
          end

          context 'search for "s"' do
            it 'returns Stephenson' do
              get :names_for_dropdown, format: :json, id: student.id, term: 's'
              expect(json).to eq ['Stephenson, Neal']
            end
          end

        end

        context 'no educators at school or providing services' do
          let(:school) { FactoryGirl.create(:healey) }
          it 'returns an empty array' do
            expect(json).to eq []
          end
        end

      end
    end

    context 'unauthorized' do
      it 'returns unauthorized' do
        make_request(FactoryGirl.create(:student))
        expect(response).to have_http_status(:unauthorized)
      end
    end

  end

  describe '#reset_session_clock' do
    def make_request
      request.env['HTTPS'] = 'on'
      request.env["devise.mapping"] = Devise.mappings[:educator]
      get :reset_session_clock, format: :json
    end

    context 'educator is not logged in' do
      it 'returns 401 Unauthorized' do
        make_request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'educator is logged in' do
      before(:each) do
        sign_in FactoryGirl.create(:educator)
        make_request
      end
      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end
      it 'resets the session clock' do
        # TODO: Get Devise test helpers like `educator_session`
        # working within the Rspec controller context:
        # expect(educator_session["last_request_at"]).eq Time.now
      end
    end

  end
end
