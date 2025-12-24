# == Schema Information
#
# Table name: diary_users
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  diary_id   :integer          not null
#  role       :string           default("viewer"), not null  # owner, editor, viewer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_diary_users_on_diary_id              (diary_id)
#  index_diary_users_on_user_id               (user_id)
#  index_diary_users_on_user_id_and_diary_id  (user_id,diary_id) UNIQUE
#
# Foreign Keys
#
#  diary_id  (diary_id => diaries.id)
#  user_id   (user_id => users.id)
#

class DiaryUser < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :diary

  # Validations
  validates :role, presence: true, inclusion: { in: %w[owner editor viewer] }
  validates :user_id, uniqueness: { scope: :diary_id, message: "이미 공유된 사용자입니다" }

  # Scopes
  scope :owners, -> { where(role: "owner") }
  scope :editors, -> { where(role: "editor") }
  scope :viewers, -> { where(role: "viewer") }
end
