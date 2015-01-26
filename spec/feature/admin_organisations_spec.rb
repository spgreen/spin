require 'rails_helper'

RSpec.feature 'Managing the Organisation', type: :feature do
  given(:user) do
    create(:subject, :authorized,
           permission: 'organisations:*')
  end

  given!(:organisation) { create(:organisation) }

  background do
    attrs = create(:aaf_attributes, :from_subject, subject: user)
    RapidRack::TestAuthenticator.jwt = create(:jwt, aaf_attributes: attrs)
    visit '/'
    check 'agree_to_consent'
    click_button 'Log In'
    expect(current_path).to eq('/auth/login')
    click_button 'Login'

    click_link('Organisations', match: :first)
    expect(current_path).to eq('/admin/organisations')
  end

  scenario 'shows the organisation name in the list' do
    expect(page).to have_css('table tr td', text: organisation.name)
  end

  scenario 'shows the organisation description in the list' do
    expect(page).to have_css('table tr td', text: organisation.external_id)
  end

  scenario 'shows actions for the organisation' do
    expect(page).to have_content('Projects (0) Edit Delete')
  end

  scenario 'shows New Organisation button' do
    expect(page).to have_content('New Organisation')
  end

  context 'delete existing' do
    before do
      click_link 'Delete'
    end

    scenario 'does not shows the organisation name in the list' do
      expect(page).to_not have_css('table tr td', text: organisation.name)
    end

    scenario 'does not shows the organisation description in the list' do
      expect(page).to_not have_css('table tr td',
                                   text: organisation.external_id)
    end

    scenario 'does not shows actions for the organisation' do
      expect(page).to_not have_content('Projects (0) Edit Delete')
    end
  end

  context 'edit existing' do
    before do
      click_link 'Edit'
    end

    scenario 'redirects to edit path' do
      expect(current_path).to eq("/admin/organisations/#{organisation.id}/edit")
    end

    scenario 'shows populated name field' do
      expect(page).to have_field('organisation_name', with: organisation.name)
    end

    scenario 'shows populated external_id field' do
      expect(page).to have_field('organisation_external_id',
                                 with: organisation.external_id)
    end

    scenario 'cancels' do
      click_link 'Cancel'
      expect(current_path).to eq('/admin/organisations')
    end

    context 'saves' do
      given(:more_bs) { Faker::Company.bs }

      before do
        fill_in 'organisation_name', with: more_bs
        click_button 'Save'
      end

      scenario 'redirects back to organisations' do
        expect(current_path).to eq('/admin/organisations')
      end

      scenario 'shows flash message' do
        expect(page).to have_content("Updated Organisation: #{more_bs}")
      end

      scenario 'shows the updated organisation' do
        expect(page).to have_css('table tr td', text: more_bs)
      end
    end
  end

  context 'creating new' do
    before do
      click_link 'New Organisation'
    end

    scenario 'redirects to new path' do
      expect(current_path).to eq('/admin/organisations/new')
    end

    scenario 'cancels' do
      click_link 'Cancel'
      expect(current_path).to eq('/admin/organisations')
    end

    context 'saves' do
      given(:bs) { Faker::Company.bs }
      given(:external_id) { Faker::Lorem.characters(10) }

      context 'with invalid data' do
        before do
          fill_in 'organisation_external_id', with: external_id
          click_button 'Create'
        end

        scenario 'shows flash message' do
          expect(page).to have_content('Unable to create Organisation' \
                                       ' Name can’t be blank')
        end
      end

      context 'with valid data' do
        before do
          fill_in 'organisation_name', with: bs
          fill_in 'organisation_external_id', with: external_id
          click_button 'Create'
        end

        scenario 'redirects back to organisations' do
          expect(current_path).to eq('/admin/organisations')
        end

        scenario 'shows flash message' do
          expect(page).to have_content("Created new Organisation: #{bs}")
        end

        scenario 'shows the created organisation' do
          expect(page).to have_css('table tr td', text: bs)
        end
      end
    end
  end
end