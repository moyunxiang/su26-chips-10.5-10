# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MyEventsController do
  let(:user) { User.create!(provider: :developer, uid: 'u-1') }
  let(:state) do
    State.create!(name: 'California', symbol: 'CA', fips_code: 6, is_territory: 0,
                  lat_min: 0, lat_max: 1, long_min: 0, long_max: 1)
  end
  let(:county) { County.create!(name: 'Alameda', state: state, fips_code: 1, fips_class: 'H1') }
  let(:valid_attrs) do
    { name: 'Rally', county_id: county.id, description: 'A rally',
      start_time: 1.day.from_now, end_time: 2.days.from_now }
  end

  before { session[:user_id] = user.id }

  it 'requires login' do
    session.delete(:user_id)
    get :new
    expect(response).to redirect_to(login_url)
  end

  describe 'GET new' do
    it 'renders the new form' do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    it 'creates an event and redirects' do
      expect { post :create, params: { event: valid_attrs } }.to change(Event, :count).by(1)
      expect(response).to redirect_to(events_path)
    end

    it 're-renders on invalid input' do
      post :create, params: { event: valid_attrs.merge(start_time: nil) }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PUT update' do
    let(:event) { Event.create!(valid_attrs) }

    it 'updates and redirects' do
      put :update, params: { id: event.id, event: { name: 'Renamed' } }
      expect(response).to redirect_to(events_path)
      expect(event.reload.name).to eq('Renamed')
    end
  end

  describe 'DELETE destroy' do
    let(:event) { Event.create!(valid_attrs) }

    it 'destroys the event' do
      event
      expect { delete :destroy, params: { id: event.id } }.to change(Event, :count).by(-1)
    end
  end
end
