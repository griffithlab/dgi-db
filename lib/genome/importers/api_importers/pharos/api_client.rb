require 'open-uri'

module Genome; module Importers; module ApiImporters; module Pharos;
  class ApiClient
    def genes_for_category(category, start=0, count=10)
      get_entries(gene_lookup_base_url, category, start, count)
    end

    def get_entries(url, category, start, count)
      uri = URI.parse(url).tap do |u|
        u.query = URI.encode_www_form(params(category, start, count))
      end
      body = make_get_request(uri)
      JSON.parse(body)['data']['search']['targetResult']['targets']
    end

    def make_get_request(uri)
      res = Net::HTTP.get_response(uri)
      raise StandardError.new("Request Failed!") unless res.code == '200'
      res.body
    end

    def gene_lookup_base_url
      "https://pharos-api.ncats.io/graphql"
    end

    def params(category, start, count)
      {
        'query' => "{search(term: \"#{category}\", facets: \"Family\"){\n    targetResult {count, targets(skip: #{start}, top:#{count}) { uniprot, name, sym } }\n  }\n}"
      }
    end
  end
end; end; end; end
