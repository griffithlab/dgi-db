require 'nokogiri'
require 'open-uri'
require 'net/https'

module Genome; module Importers; module ApiImporters; module JaxCkb;
  class ApiClient
    def genes
      get_json(gene_base_url)
    end

    def interactions_for_gene_id(id)
      get_html(gene_lookup_base_url(id))
    end

    private
    def get_json(base_url)
      uri = URI.parse(base_url)
      body = make_get_request(uri)
      JSON.parse(body)
    end

    def make_get_request(uri)
      res = Net::HTTP.get_response(uri)
      raise StandardError.new("Request Failed!") unless res.code == '200'
      res.body
    end

    def get_html(base_url)
      page = Nokogiri::HTML(open(base_url))
      table = page.css('#associatedEvidence')
      headers = table.xpath('table/thead//th').map{|h| h.text}
      rows = []
      index = 0
      row = {}
      table.xpath('table//td').each do |td|
        row[headers[index]] = td.text.strip
        index += 1
        if index == headers.size
          rows << row
          index = 0
          row = {}
        end
      end
      return rows
    end

    def gene_base_url
      "https://ckb.jax.org/select2/getSelect2GenesForSearchTerm"
    end

    def gene_lookup_base_url(id)
      "https://ckb.jax.org/gene/show?geneId=#{id}&tabType=GENE_LEVEL_EVIDENCE"
    end
  end
end; end; end; end
