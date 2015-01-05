require 'rails_helper'

module Authentication
  RSpec.describe SubjectReceiver do
    subject(:receiver) { SubjectReceiver.new }
    let(:env) { {} }

    context '#map_attributes' do
      let(:attrs) do
        keys = %w(edupersontargetedid auedupersonsharedtoken displayname mail)
        keys.reduce({}) { |a, e| a.merge(e => e) }
      end

      it 'maps the attributes' do
        expect(receiver.map_attributes(env, attrs))
          .to eq(name: 'displayname',
                 mail: 'mail',
                 shared_token: 'auedupersonsharedtoken',
                 targeted_id: 'edupersontargetedid')
      end
    end

    context '#subject' do
      let(:attributes) do
        attributes_for(:subject)
      end
      let(:updated_attributes) do
        attributes.merge(name: Faker::Name.name,
                         mail: Faker::Internet.email)
      end

      context 'with mocked http session vars' do
        let(:remote_host) { Faker::Internet.url }
        let(:remote_addr) { Faker::Internet.ip_v4_address }
        let(:user_agent) { Faker::Lorem.characters }
        let(:env) do
          { 'REMOTE_HOST' => remote_host,
            'REMOTE_ADDR' => remote_addr,
            'HTTP_USER_AGENT' => user_agent }
        end

        subject { receiver.subject(env, attributes) }

        it 'changes the SubjectSession count' do
          expect { subject }
            .to change(SubjectSession, :count).by(1)
        end

        it 'contains the fields from the http session' do
          receiver.subject(env, attributes)

          expect(SubjectSession.last)
            .to have_attributes(id: SubjectSession.last.id,
                                remote_host: remote_host,
                                remote_addr: remote_addr,
                                http_user_agent: user_agent,
                                subject_id: subject.id)
        end

        context 'without an existing Subject' do
          it 'stores a new Subject' do
            expect { subject }
              .to change(Subject, :count).by(1)
          end

          it { is_expected.to be_a(Subject) }
          it { is_expected.to have_attributes(attributes) }
        end

        context 'with an existing Subject' do
          let!(:created_subject) { receiver.subject(env, attributes) }
          subject { receiver.subject(env, updated_attributes).reload }

          it { is_expected.to eq(created_subject) }
          it { is_expected.to have_attributes(updated_attributes) }
        end
      end
    end

    context 'after authenticating with idP' do
      include_context 'a mocked subject'

      let(:env) do
        { 'rack.session' => { 'subject_id' => 1 } }
      end

      context 'with no projects' do
        include_context 'with no projects'

        it 'redirects to no projects assigned page' do
          expect(receiver.finish(env))
            .to eq([302, { 'Location' => '/no_projects_assigned' }, []])
        end
      end

      context 'with 1 project' do
        include_context 'with 1 project'

        it 'redirects to aws auth' do
          expect(receiver.finish(env))
            .to eq([302, { 'Location' => '/aws_idp' }, []])
        end
      end

      context 'with more than 1 project' do
        include_context 'with 3 projects'

        it 'redirects to projects page' do
          expect(receiver.finish(env))
            .to eq([302, { 'Location' => '/projects' }, []])
        end
      end
    end
  end
end
