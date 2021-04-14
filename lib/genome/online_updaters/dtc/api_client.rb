module Genome; module OnlineUpdaters; module DTC
  class ApiClient
    def interactions(offset=0, limit=20)
      variants = JSON.parse(get_page(bioactivities_url, offset, limit))
    end

    def bioactivities_url
      'https://drugtargetcommons.fimm.fi/api/data/bioactivity/'
    end

    def get_page(url, offset, limit)
      uri = URI.parse(url).tap do |u|
        u.query = URI.encode_www_form(params(offset, limit))
      end
      make_get_request(uri)
    end

    def make_get_request(uri)
      resp = Net::HTTP.get_response(uri)
      if resp.code != '200'
        raise StandardError.new('Failed HTTP request')
      end
      resp.body
    end

    def params(offset, limit)
      {
        'format' => 'json',
        'offset' => offset,
        'limit' => limit
      }
    end
  end
end; end; end
