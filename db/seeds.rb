# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require_relative 'seed_data'

if State.none?
  SeedData.states.each do |state_data|
    state = State.find_or_create_by!(state_data)

    county_filename = "lib/assets/counties_fips_data/#{state.symbol.downcase}.json"
    Rails.root.join(county_filename).open('r:UTF-8') do |f|
      state.counties = JSON.parse(f.read, object_class: County)
    end
    state.save
  end
end

# Seed the demo representatives, news, and events in development and in
# production, so the live Render demo has data to show (states/counties above
# are always seeded). Each news item is tagged with an Issue (Task 2.1) by
# cycling through the fixed list, so the Issue column is populated for the demo.
if Rails.env.development? || Rails.env.production?
  Representative.destroy_all
  issue_cycle = NewsItem.issues.cycle
  SeedData.representatives.each do |rep|
    rep_model = Representative.find_or_create_by(name: rep[:name])
    rep[:news_items].each do |news_item|
      NewsItem.find_or_create_by(
        representative: rep_model,
        title:          news_item[:title],
        description:    news_item[:description],
        link:           news_item[:link]
      ) do |item|
        item.issue = issue_cycle.next
      end
    end
  end

  SeedData.events.each do |event|
    state = State.find_by!(symbol: event[:state_symbol])
    county = County.find_by!(state_id: state.id, fips_code: event[:fips_code])
    Event.create(
      name:        event[:name],
      description: event[:description],
      county:      county,
      start_time:  event[:start_time],
      end_time:    event[:end_time]
    )
  end
end
