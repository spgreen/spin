class Permission < ActiveRecord::Base
  include Lipstick::AutoValidation

  audited associated_with: :role

  belongs_to :role

  valhammer

  # "word" in the url-safe base64 alphabet, or single '*'
  SEGMENT = /([\w-]+|\*)/
  private_constant :SEGMENT
  validates :value, format: Accession::Permission.regexp
end
