require 'open-uri'

module Genome; module Importers; module ApiImporters; module Go;
  class ApiClient
    def genes_for_go_id(id, start=0, rows=500)
      get_entries(gene_lookup_base_url(id), start, rows)
    end

    def get_entries(url, start, rows)
      uri = URI.parse(url).tap do |u|
        u.query = URI.encode_www_form(params(start, rows))
      end
      body = make_get_request(uri)
      JSON.parse(body)
    end

    def make_get_request(uri)
      res = Net::HTTP.get_response(uri)
      raise StandardError.new("Request Failed!") unless res.code == '200'
      res.body
    end

    def gene_lookup_base_url(id)
      "http://api.geneontology.org/api/bioentity/function/%22GO:#{id}%22"
    end

    def params(start, rows)
      {
        'start' => start,
        'rows' => rows,
      }
    end
  end
end; end; end; end
