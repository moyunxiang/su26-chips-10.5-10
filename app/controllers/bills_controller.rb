# frozen_string_literal: true

require_relative '../../lib/congress-api'

class BillsController < ApplicationController
  def index
    @bill_types = Bill.searchable_types
    @congress = params[:congress].presence
    @bill_type = params[:bill_type].presence
    @results = []
    @total_count = 0
    @error = nil

    if @bill_type && @congress.blank?
      @error = 'Please provide a congress session number to search by bill type.'
      return
    end

    if congress_api_key.blank?
      @error = 'Bill search is temporarily unavailable (no congress.gov API key configured).'
      return
    end

    perform_search
  end

  def show
    @bill = Bill.find(params[:id])
  end

  def create
    attrs = bill_params
    attrs[:summary] = fetch_summary(attrs)
    @bill = Bill.new(attrs)
    if @bill.save
      redirect_to bill_path(@bill), notice: 'Bill was successfully saved.'
    else
      redirect_to bills_path, alert: 'Could not save the bill.'
    end
  end

  private

  def perform_search
    response = congress_client.get(search_path, limit: 50)
    bills = response['bills'] || []
    @results = bills.map { |bill| Bill.from_api(bill) }
    @total_count = response.dig('pagination', 'count') || @results.size
  rescue Congress::APIError => e
    @error = "Could not reach congress.gov: #{e.message}"
  end

  def search_path
    if @congress && @bill_type
      "/bill/#{@congress}/#{@bill_type}"
    elsif @congress
      "/bill/#{@congress}"
    else
      '/bill'
    end
  end

  # Fetches the latest summary text for a bill from congress.gov. Returns nil if
  # the bill is under-specified or the API is unavailable, so a save still works.
  def fetch_summary(attrs)
    return nil unless summary_fetchable?(attrs)

    response = congress_client.get("/bill/#{attrs[:congress]}/#{attrs[:type]}/#{attrs[:number]}/summaries")
    summaries = response['summaries'] || []
    summaries.last&.dig('text')
  rescue Congress::APIError
    nil
  end

  def summary_fetchable?(attrs)
    attrs[:congress].present? && attrs[:type].present? &&
      attrs[:number].present? && congress_api_key.present?
  end

  def bill_params
    params.require(:bill).permit(:title, :congress, :number, :type, :original_chamber)
  end

  def congress_api_key
    ENV.fetch('CONGRESS_GOV_API_KEY') { Rails.application.credentials.congress_gov_api_key }
  end

  def congress_client
    Congress::API.new(congress_api_key)
  end
end
