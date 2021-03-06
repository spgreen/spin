require 'rails_helper'

RSpec.describe AWSSessionInstancesController, type: :controller do
  shared_examples 'an aws login action' do
    let(:project_role) { create(:project_role) }
    let(:user) { create(:subject) }

    before { session[:subject_id] = user.try(:id) }
    subject { -> { run } }
    around { |e| Timecop.freeze { e.run } }

    context 'when the user is permitted' do
      before { user.project_roles << project_role }

      it { is_expected.to change(AWSSessionInstance, :count).by(1) }

      context 'the response' do
        before do
          allow(Rails.application.config.spin_service)
            .to receive(:login_jwt_secret).and_return(secret)

          run
        end

        subject { response }
        let(:secret) { SecureRandom.hex }
        let(:claims) do
          JSON::JWT.decode(response.cookies['spin_login'], secret)
        end

        it 'redirects to the IdP' do
          url = %r{/idp/profile/SAML2/Unsolicited/SSO.*}
          expect(subject).to redirect_to(url)
        end

        it 'includes the session instance in the url' do
          identifier = AWSSessionInstance.last.identifier
          expect(claims['sub']).to eq(identifier)
        end

        it 'expires the session in two minutes' do
          expect(claims['exp']).to eq(2.minutes.from_now.utc.to_i)
        end
      end
    end

    context 'when the user has no project role' do
      it { is_expected.not_to change(AWSSessionInstance, :count) }

      context 'the response' do
        before { run }
        subject { response }

        it { is_expected.to have_http_status(:forbidden) }
        it { is_expected.to render_template('errors/forbidden') }
      end
    end

    context 'when the user has no active project roles' do
      let(:project) { create(:project, active: false) }
      let(:project_role) { create(:project_role, project: project) }

      before { user.project_roles << project_role }

      it { is_expected.not_to change(AWSSessionInstance, :count) }

      context 'the response' do
        before { run }
        subject { response }

        it { is_expected.to have_http_status(:forbidden) }
        it { is_expected.to render_template('errors/forbidden') }
      end
    end
  end

  context '#auto' do
    def run
      get :auto
    end

    it_behaves_like 'an aws login action'
  end

  context '#login' do
    def run
      post :login, project_role_id: project_role.id.to_s
    end

    it_behaves_like 'an aws login action'
  end
end
