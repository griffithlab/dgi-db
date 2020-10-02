module Genome; module Importers; module ApiImporters; module Oncokb;
  class ApiClient
    def variants
      get_data(variant_base_url, {})
    end

    def genes
      get_data(gene_base_url, {})
    end

    def drugs
      get_data(drug_base_url, {})
    end

    def gene_for_name(name)
      get_data(gene_lookup_base_url, gene_params(name))
    end

    def drug_for_name(name)
      get_data(drug_lookup_base_url, drug_params(name))
    end

    private
    def get_data(base_url, params)
      uri = URI.parse(base_url).tap do |u|
        u.query = URI.encode_www_form(params)
      end
      body = make_get_request(uri)
      JSON.parse(body)
    end

    def make_get_request(uri)
      res = Net::HTTP.get_response(uri)
      raise StandardError.new("Request Failed!") unless res.code == '200'
      res.body
    end

    def variant_base_url
      "http://oncokb.org/api/v1/utils/allActionableVariants"
    end

    def gene_base_url
      "http://oncokb.org/api/v1/genes"
    end

    def gene_loopup_base_url
      "http://oncokb.org/api/v1/genes/lookup"
    end

    def gene_params(name)
      {
        'query' => name,
      }
    end

    def drug_base_url
      "http://oncokb.org/api/v1/drugs"
    end

    def drug_loopkup_base_url
      "http://oncokb.org/api/v1/drugs/lookup"
    end

    def drug_params(name)
      {
        'name' => name,
        'exactMatch' => 'true',
      }
    end
  end
end; end; end; end
