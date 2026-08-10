# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserController do
  let(:user) { User.create!(provider: :developer, uid: 'u-1', first_name: 'Ada', last_name: 'Lovelace') }

  describe 'GET profile' do
    it 'redirects to login when logged out' do
      get :profile
      expect(response).to redirect_to(login_url)
    end

    it 'renders the profile for a logged-in user' do
      session[:user_id] = user.id
      get :profile
      expect(response).to have_http_status(:ok)
      expect(assigns(:user)).to eq(user)
    end
  end
end
