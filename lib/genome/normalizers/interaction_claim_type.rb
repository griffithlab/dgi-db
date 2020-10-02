module Genome
  module Normalizers
    class InteractionClaimType
      def self.normalize_types
        ActiveRecord::Base.transaction do
          normalize_existing_types
          fill_in_new_types
          cleanup_type(default_type)
          cleanup_type(other_type)
          # remove_empty_types
        end
      end

      def self.normalize_existing_types
        DataModel::InteractionClaimType.all.each do |ict|
          normalized_ict = DataModel::InteractionClaimType.where(type: name_normalizer(ict.type)).first_or_create()
          if ict != normalized_ict
            ict.interaction_claims.each do |ic|
              add_unless_exists(normalized_ict, ic)
              ic.interaction_claim_types.delete(ict)
              ic.save
            end
            ict.interactions.each do |i|
              add_unless_exists_for_interaction(normalized_ict, i)
              i.interaction_types.delete(ict)
              i.save
            end
            ict.delete
          end
        end
      end

      def self.fill_in_new_types
        existing_types = all_interaction_claim_types
        claim_type_attributes.each do |ica|
          if type = existing_types[name_normalizer(ica.value)]
            add_unless_exists(type, ica.interaction_claim)
          end
          ica.delete
        end
      end

      def self.cleanup_type(type)
        type.interaction_claims.each do |ic|
          ic.interaction_claim_types.delete(type)
          ic.save
        end
      end

      def self.default_type
        DataModel::InteractionClaimType.find_by(type: 'n/a')
      end

      def self.other_type
        DataModel::InteractionClaimType.find_by(type: 'other/unknown')
      end

      def self.add_unless_exists(type, interaction_claim)
        unless interaction_claim.interaction_claim_types.include?(type)
          interaction_claim.interaction_claim_types << type
        end
      end

      def self.add_unless_exists_for_interaction(type, interaction)
        unless interaction.interaction_types.include?(type)
          interaction.interaction_types << type
        end
      end

      def self.name_normalizer(val)
        val = val.downcase.strip
        if val == 'na' || val == 'n/a'
          'n/a'
        elsif val =~ /other/ || val =~ /unknown/ || val == 'protector' || val == 'oxidizer' || val == 'coating agent' || val == 'dilator' || val == 'deoxidizer' || val == 'diffusing substance'|| val == 'vesicant' || val == 'gene replacement'
          'other/unknown'
        elsif val == 'neutralizer' || val == 'reducer' || val == 'metabolizer' || val == 'acetylation' || val == 'chelator' || val == 'cross-linking/alkylation' || val == 'regulator'
          'modulator'
        elsif val == 'positive allosteric modulator' || val == 'regulator (upregulator)' || val == 'enhancer' || val == 'modulator (allosteric modulator)'
          'positive modulator'
        elsif val == 'inhibitor, competitive' || val == 'gating inhibitor' || val == 'inhibitor; antagonist; blocker' || val == 'inhibitor (gating inhibitor)' || val == 'growth_inhibition' || val == 'inhibition' || val == 'weak inhibitor' || val == 'aggregation inhibitor' || val == 'inhibition of synthesis' || val == "translocation inhibitor" || val == 'inhibits downstream inflammation cascades' || val == 'inactivator' || val == 'inihibitor' || val == 'inhibitors' || val == 'Anti-angiogenic.'
          'inhibitor'
        elsif val == 'channel blocker' || val == 'blocker (channel blocker)' || val == 'nucleotide exchange blocker'
          'blocker'
        elsif val == 'antisense' || val == 'sirna drug'
          'antisense oligonucleotide'
        elsif val == 'binding' || val == 'binder (minor groove binder)' || val == 'breaker'
          'binder'
        elsif val == 'incorporation into and destabilization' || val == 'intercalation' || val == 'desensitize the target' || val == 'disrupter' || val == 'intercalator' || val == 'downregulator'
          'negative modulator'
        elsif val == 'inhibitory immune response' || val == 'car-t-cell-therapy(dual specific)' || val == 'immunomodulator' || val == 'immunomodulator (immunostimulant)' || val == 'immune response agent' || val == 'car-t-cell-therapy' || val == 'immune response agent' || val == 'immunostimulant' || val == 'immunostimulator' || val == 'Radioimmunotherapy'
          'immunotherapy'
        elsif val == 'component of'
          'product of'
        elsif val == 'opener'
          'potentiator'
        elsif val == 'stablizer' || val == 'stabilization' || val == 'stabilizer'
          'chaperone'
        elsif val == 'reactivator'
          'activator'
        elsif val == 'co-agonist'
          'agonist'
        elsif val == 'agonis; inverse agonist' || val == 'inverse_agonist'
          'inverse agonist'
        elsif val == 'cytotoxicity'
          'cytotoxic'
        elsif val == 'degradation'
          'cleavage'
        else
          val
        end
      end

      def self.claim_type_attributes
        DataModel::InteractionClaimAttribute.where('lower(name) = ?', 'interaction type')
        .includes(interaction_claim: [:interaction_claim_types])
      end

      def self.all_interaction_claim_types
        DataModel::InteractionClaimType.all.each_with_object({}) do |i, h|
          h[i.type] = i
        end
      end

      def self.remove_empty_types
        DataModel::InteractionClaimType.includes(:interaction_claims).where(interaction_claims: {id: nil}).destroy_all
      end
    end
  end
end
