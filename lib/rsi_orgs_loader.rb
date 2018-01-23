# frozen_string_literal: true

class RsiOrgsLoader
  attr_accessor :base_url

  def initialize(options = {})
    @base_url = options[:base_url] || "https://robertsspaceindustries.com"
  end

  def fetch(sid)
    data = fetch_org_data(sid)

    OpenStruct.new(data) if data.present?
  end

  def fetch_members(sid, count)
    members = []

    (count / 32.0).to_f.ceil.times do |index|
      member_response = Typhoeus.post(
        "#{base_url}/api/orgs/getOrgMembers",
        headers: {
          'content-type' => 'application/json'
        },
        body: JSON.dump(
          symbol: sid,
          pagesize: 32,
          page: index + 1
        )
      )

      next unless member_response.success?

      begin
        json_data = JSON.parse(member_response.body)
        next unless json_data['data']
        members_raw = Nokogiri::HTML(json_data['data']['html'])
        members_raw.css('.member-item').each do |member_item|
          members << {
            name: member_item.css('.name').text.strip,
            handle: member_item.css('.nick').text.strip,
            rank: member_item.css('.rank').text.strip
          }
        end
      rescue JSON::ParserError
        Rails.logger.error "Model Data could not be parsed: #{response.body}"
      end

      sleep 0.5
    end

    members
  end

  def fetch_citizen(handle)
    response = Typhoeus.get("https://robertsspaceindustries.com/citizens/#{handle}")

    return unless response.success?

    parse_citizen(Nokogiri::HTML(response.body))
  end

  private def parse_citizen(page)
    user = RsiUser.new
    page.css('.info .value').each_with_index do |value, index|
      user.username = value.text.strip if index.zero?
      user.handle = value.text.strip if index == 1
      user.title = value.text.strip if index == 2
    end
    if page.css('.profile .thumb img').present?
      user.avatar = "https://robertsspaceindustries.com#{page.css('.profile .thumb img')[0]['src']}"
    end
    if page.css('.profile-content .bio').present?
      user.bio = page.css('.profile-content .bio').text.strip
    end
    user.citizen_record = page.css('.citizen-record .value').text.strip
    page.css('.profile-content > .left-col .value').each_with_index do |value, index|
      if index.zero?
        user.enlisted = value.text.strip
      elsif index == 1
        user.location = value.text.strip
      elsif index == 2
        user.languages = value.text.strip
      end
    end
    user
  end

  private def fetch_org_data(sid)
    response = Typhoeus.get("#{base_url}/orgs/#{sid}")
    return if response.code != 200
    page = Nokogiri::HTML(response.body)
    org_box = page.css('#organization')
    org_data = {}
    org_data[:name] = org_box.css('.heading h1').text.delete('/').gsub(sid.upcase, '').strip
    org_data[:sid] = sid.downcase
    org_data[:archetype] = org_box.css('.heading .tags .model').text.strip
    org_data[:commitment] = org_box.css('.heading .tags .commitment').text.strip
    org_data[:rpg] = org_box.css('.heading .tags .roleplay').text.strip.present?
    org_data[:exclusive] = org_box.css('.heading .tags .exclusive').text.strip.present?
    org_data[:main_activity] = org_box.css('.heading .focus .primary .content').text.strip
    org_data[:secondary_activity] = org_box.css('.heading .focus .secondary .content').text.strip
    org_data[:recruiting] = org_box.css('.join-us .bt-join').text.strip.present?
    org_data[:member_count] = org_box.css('.heading .logo .count').text.strip.gsub(' members', '').gsub(' member', '').to_i || 1
    if org_box.css('.heading .logo img').present?
      org_data[:logo] = "https://robertsspaceindustries.com#{org_box.css('.heading .logo img')[0]['src']}"
    end
    org_data
  end
end
