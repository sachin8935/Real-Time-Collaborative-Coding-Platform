class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Collab::HasCollaborativeDocument
  include Collab::HasTrackedDocumentPositions
end
