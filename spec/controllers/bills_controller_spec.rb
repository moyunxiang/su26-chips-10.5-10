# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BillsController do
  let(:client) { instance_double(Congress::API) }
  let(:api_response) do
    {
      'bills' => [
        { 'title' => 'A Test Bill', 'congress' => 118, 'number' => 123, 'type' => 'HR',
          'originChamber' => 'House',
          'latestAction' => { 'actionDate' => '2024-04-06', 'text' => 'Became Public Law No: 117-108.' } }
      ],
      'pagination' => { 'count' => 250 }
    }
  end

  before do
    ENV['CONGRESS_GOV_API_KEY'] = 'test-key'
    allow(Congress::API).to receive(:new).and_return(client)
  end

  after { ENV.delete('CONGRESS_GOV_API_KEY') }

  describe 'GET index' do
    it 'renders the search page' do
      allow(client).to receive(:get).and_return(api_response)
      get :index
      expect(response).to have_http_status(:ok)
    end

    it 'shows the 50 most recent bills when no params are given' do
      allow(client).to receive(:get).and_return(api_response)
      get :index
      expect(client).to have_received(:get).with('/bill', hash_including(limit: 50))
      expect(assigns(:results).size).to eq(1)
      expect(assigns(:total_count)).to eq(250)
    end

    it 'queries the congress/type endpoint when both are provided' do
      allow(client).to receive(:get).and_return(api_response)
      get :index, params: { congress: '118', bill_type: 'hr' }
      expect(client).to have_received(:get).with('/bill/118/hr', hash_including(limit: 50))
    end

    it 'refuses to search by bill type without a congress number' do
      get :index, params: { bill_type: 'hr' }
      expect(assigns(:error)).to be_present
      expect(assigns(:results)).to be_empty
    end

    it 'reports a friendly error when the API is unreachable' do
      allow(client).to receive(:get).and_raise(Congress::APIError, 'boom')
      get :index
      expect(assigns(:error)).to include('congress.gov')
      expect(assigns(:results)).to be_empty
    end

    it 'degrades gracefully when no API key is configured' do
      ENV.delete('CONGRESS_GOV_API_KEY')
      allow(Rails.application.credentials).to receive(:congress_gov_api_key).and_return(nil)
      get :index
      expect(assigns(:error)).to be_present
    end
  end

  describe 'POST create' do
    let(:bill_attrs) do
      { title: 'A Test Bill', congress: '118', number: '123', type: 'hr', original_chamber: 'House' }
    end
    let(:summaries_response) do
      { 'summaries' => [{ 'text' => 'An older summary.' }, { 'text' => 'The latest summary.' }] }
    end

    it 'saves the bill with its summary and redirects to the show page' do
      allow(client).to receive(:get).and_return(summaries_response)
      expect { post :create, params: { bill: bill_attrs } }.to change(Bill, :count).by(1)
      bill = Bill.last
      expect(bill.summary).to eq('The latest summary.')
      expect(response).to redirect_to(bill_path(bill))
    end

    it 'still saves the bill when the summary API fails' do
      allow(client).to receive(:get).and_raise(Congress::APIError, 'boom')
      expect { post :create, params: { bill: bill_attrs } }.to change(Bill, :count).by(1)
      expect(Bill.last.summary).to be_nil
    end
  end

  describe 'GET show' do
    it 'renders a saved bill' do
      bill = Bill.create!(title: 'Saved Bill', congress: 118, number: 7, type: 'hr',
                          original_chamber: 'House', summary: 'Summary text.')
      get :show, params: { id: bill.id }
      expect(response).to have_http_status(:ok)
      expect(assigns(:bill)).to eq(bill)
    end
  end
end
