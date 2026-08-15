# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsController do
  let(:state) do
    State.create!(name: 'California', symbol: 'CA', fips_code: 6, is_territory: 0,
                  lat_min: 0, lat_max: 1, long_min: 0, long_max: 1)
  end
  let(:county) { County.create!(name: 'Alameda', state: state, fips_code: 1, fips_class: 'H1') }
  let!(:event) do
    Event.create!(name: 'Town Hall', county: county,
                  start_time: 1.day.from_now, end_time: 2.days.from_now)
  end

  describe 'GET index' do
    it 'lists all events with no filter' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:events)).to include(event)
    end

    it 'filters events by state only' do
      get :index, params: { 'filter-by' => 'state-only', 'state' => 'ca' }
      expect(assigns(:events)).to include(event)
      expect(assigns(:state)).to eq(state)
    end

    it 'filters events by county' do
      get :index, params: { 'filter-by' => 'county', 'state' => 'ca', 'county' => '1' }
      expect(assigns(:events)).to include(event)
      expect(assigns(:county)).to eq(county)
    end
  end

  describe 'GET show' do
    it 'renders a single event' do
      get :show, params: { id: event.id }
      expect(response).to have_http_status(:ok)
      expect(assigns(:event)).to eq(event)
    end
  end
end
