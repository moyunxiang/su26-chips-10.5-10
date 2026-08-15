# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MyNewsItemsController do
  let(:user) { User.create!(provider: :developer, uid: 'u-1') }
  let(:representative) { Representative.create!(name: 'Ada Lovelace', ocdid: '111', title: 'Senator') }
  let(:valid_attrs) do
    { title: 'Headline', link: 'http://news.test', description: 'Body',
      issue: 'Climate Change', representative_id: representative.id }
  end

  before { session[:user_id] = user.id }

  it 'requires login' do
    session.delete(:user_id)
    get :new, params: { representative_id: representative.id }
    expect(response).to redirect_to(login_url)
  end

  describe 'GET new' do
    it 'renders the new form' do
      get :new, params: { representative_id: representative.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    it 'creates a news item with an issue and redirects' do
      expect do
        post :create, params: { representative_id: representative.id, news_item: valid_attrs }
      end.to change(NewsItem, :count).by(1)
      expect(NewsItem.last.issue).to eq('Climate Change')
    end

    it 're-renders on invalid input' do
      post :create, params: { representative_id: representative.id,
                              news_item: valid_attrs.merge(representative_id: nil) }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PUT update' do
    let(:news_item) { NewsItem.create!(valid_attrs) }

    it 'updates and redirects' do
      put :update, params: { representative_id: representative.id, id: news_item.id,
                             news_item: { title: 'Renamed' } }
      expect(news_item.reload.title).to eq('Renamed')
    end
  end

  describe 'DELETE destroy' do
    let(:news_item) { NewsItem.create!(valid_attrs) }

    it 'destroys the news item' do
      news_item
      expect do
        delete :destroy, params: { representative_id: representative.id, id: news_item.id }
      end.to change(NewsItem, :count).by(-1)
    end
  end
end
