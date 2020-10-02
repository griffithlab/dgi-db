module Genome; module Importers; module ApiImporters; module Civic
  class ApiClient
    def variants
      enumerate_records(variant_base_url, 1, VariantResponse)
    end

    def evidence_items_for_variant(id)
      enumerate_records(evidence_items_url_for_variant(id), 1, EvidenceItemResponse)
    end

    private
    def enumerate_records(base_url, starting_page, wrapper)
      page = get_page(base_url, starting_page, wrapper)
      Enumerator.new(page.total_count) do |y|
        page.records.each { |v| y << v }
        while page.current_page_num < page.total_pages do
          page = get_page(base_url, page.current_page_num + 1, wrapper)
          page.records.each { |v| y << v }
        end
      end
    end

    def get_page(base_url, page, wrapper)
      uri = URI.parse(base_url).tap do |u|
        u.query = URI.encode_www_form({page: page})
      end
      make_get_request(uri, wrapper)
    end

    def make_get_request(uri, wrapper)
      res = Net::HTTP.get_response(uri)
      raise StandardError.new("Request Failed!") unless res.code == '200'
      sleep(0.2)
      wrapper.new(res.body)
    end

    def variant_base_url
      "https://civicdb.org/api/variants"
    end

    def evidence_items_url_for_variant(variant_id)
      "https://civicdb.org/api/variants/#{variant_id}/evidence_items?status=accepted"
    end
  end
end; end; end; end
