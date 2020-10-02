class Updater < ApplicationJob
  attr_reader :importer

  def perform()
    ActiveRecord::Base.transaction(joinable: false, requires_new: true) do
      import
      pre_grouper = PreGrouper.new
      pre_grouper.perform
      grouper = Grouper.new
      grouper.perform(should_group_genes?, should_group_drugs?, importer.source.id)
      post_grouper = PostGrouper.new
      post_grouper.perform(should_cleanup_gene_claims?)
    end
  end

  def should_group_genes?
    raise StandardError.new('Must implement #should_group_genes? in subclass')
  end

  def should_group_drugs?
    raise StandardError.new('Must implement #should_group_drugs? in subclass')
  end

  def should_cleanup_gene_claims?
    false
  end

  def create_importer
    raise StandardError.new('Must implement #create_importer in subclass')
  end
end
