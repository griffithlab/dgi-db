require 'net/http'
require 'openssl'
require 'zip'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class UpdateCgi < TsvUpdater
  def tempfile_name
    ['cgi_biomarkers_per_variant', '.tsv']
  end

  def create_importer
    Genome::Importers::TsvImporters::Cgi.new(tempfile)
  end

  def download_file
    uri = URI('https://www.cancergenomeinterpreter.org/data/cgi_biomarkers_latest.zip')
    response = Net::HTTP.start(uri.host, uri.port,
                    :use_ssl => uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri
      http.request(request)
    end
    Zip::InputStream.open(StringIO.new(response.body)) do |io|
      while entry = io.get_next_entry
        if entry.name == 'cgi_biomarkers_per_variant.tsv'
          tempfile.write(io.read.encode("ASCII-8BIT").force_encoding("utf-8"))
        end
      end
    end
  end

  def should_group_genes?
    true
  end

  def should_group_drugs?
    true
  end

  def should_cleanup_gene_claims?
    false
  end
end
