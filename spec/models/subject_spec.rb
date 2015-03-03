require 'rails_helper'
require 'gumboot/shared_examples/subjects'

RSpec.describe Subject, type: :model do
  include_examples 'Subjects'
  it_behaves_like 'an audited model'

  context 'validations' do
    subject { build(:subject, complete: false) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:mail) }

    it { is_expected.not_to validate_presence_of(:targeted_id) }

    it { is_expected.to validate_presence_of(:shared_token) }
    it { is_expected.to validate_uniqueness_of(:shared_token) }

    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:mail).is_at_most(255) }
    it { is_expected.to validate_length_of(:targeted_id).is_at_most(255) }
    it { is_expected.to validate_length_of(:shared_token).is_at_most(255) }

    context 'with a complete subject' do
      subject { build(:subject, complete: true) }

      it { is_expected.to validate_presence_of(:targeted_id) }
      it { is_expected.to validate_presence_of(:shared_token) }
      it { is_expected.to validate_uniqueness_of(:shared_token) }
    end
  end

  context '#functioning?' do
    context 'when enabled' do
      subject { create(:subject, enabled: true) }
      it { is_expected.to be_functioning }
    end

    context 'when disabled' do
      subject { create(:subject, enabled: false) }
      it { is_expected.not_to be_functioning }
    end
  end

  context '#permits?' do
    let(:role) do
      create(:role).tap do |role|
        create(:permission, value: 'a:*', role: role)
      end
    end

    subject { create(:subject) }

    it 'derives permissions from roles' do
      subject.subject_roles.create(role_id: role.id)
      expect(subject.permits?('a:b:c')).to be_truthy
    end

    it 'only applies permissions from assigned roles' do
      role
      expect(subject.permits?('a:b:c')).to be_falsey
    end
  end

  context 'associated objects' do
    context 'subject_roles' do
      let(:child) { create(:subject_role) }
      subject { child.subject }
      it_behaves_like 'an association which cascades delete'
    end

    context 'subject_project_roles' do
      let(:child) { create(:subject_project_role) }
      subject { child.subject }
      it_behaves_like 'an association which cascades delete'
    end
  end

  describe '#active_project_roles' do
    include_context 'projects'

    subject { create(:subject) }
    let(:projects) { subject.active_project_roles }

    context 'without projects' do
      it 'provides nothing' do
        expect(projects.count).to eq(0)
      end
    end

    context 'with an active project' do
      before { create_subject_project_role_for_active_project(subject) }
      it 'provides the project' do
        expect(projects.count).to eq(1)
      end
    end

    context 'with an inactive project' do
      before { create_subject_project_role_for_inactive_project(subject) }
      it 'does not provide the project' do
        expect(projects.count).to eq(0)
      end
    end

    context 'with multiple inactive and active projects' do
      before do
        5.times { create_subject_project_role_for_active_project(subject) }
        2.times { create_subject_project_role_for_inactive_project(subject) }
      end
      it 'provides the active project only' do
        expect(projects.count).to eq(5)
      end
    end
  end
end
