module Genome; module Importers; module ApiImporters; module Docm
  class ApiClient
    def variants
      variants = JSON.parse(get_page(variant_url))
    end

    def variant_url
      'http://docm.info/api/v1/variants.json'
    end

    def get_page(url)
      uri = URI(url)

      uri.query = URI.encode_www_form(docm_params)

      req = Net::HTTP::Get.new(uri)
      resp = Net::HTTP.start(uri.host, uri.port) { |http| http.read_timeout = 1000; http.request(req)}
      if resp.code != '200'
        raise StandardError.new('Failed HTTP request')
      end

      resp.body
    end

    def docm_params
      {'detailed_view' => true}
    end
  end
end; end; end; end
