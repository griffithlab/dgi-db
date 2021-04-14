class DownloadsController < ApplicationController
  attr_reader :tsvs, :files

  def show
    @tsvs = ['interactions.tsv', 'genes.tsv', 'drugs.tsv', 'categories.tsv']
    tsv_dir = File.join('data', 'monthly_tsvs')
    unsorted_files = Dir.entries(File.join(Rails.root, 'public', tsv_dir)).each_with_object({}) do |subdir, h|
      next if subdir == '.' || subdir == '..'
      h[subdir] = tsvs.each_with_object({}) do |file, file_h|
        file_h[file] = File.join(tsv_dir, subdir, file)
      end
    end
    sorted_files = unsorted_files.sort_by{|key, values| Date.strptime(key, "%Y-%b").strftime("%s").to_i}.reverse!
    @files = sorted_files
  end
end
