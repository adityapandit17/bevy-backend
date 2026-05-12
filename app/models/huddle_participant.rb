class HuddleParticipant < ApplicationRecord
  include BelongsToTenant

  belongs_to :huddle
  belongs_to :user

  validates :user_id, uniqueness: { scope: :huddle_id }

  scope :active, -> { where(left_at: nil) }
  scope :inactive, -> { where.not(left_at: nil) }
end
