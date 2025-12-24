# == Schema Information
#
# Table name: diaries
#
#  id         :integer          not null, primary key
#  title      :string           not null              # 일기 제목
#  content    :text                                   # 일기 내용
#  user_id    :integer          not null              # 일기 작성자
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_diaries_on_created_at  (created_at)
#  index_diaries_on_user_id     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

class Diary < ApplicationRecord
  # Associations
  belongs_to :user  # 일기 작성자 (owner)
  has_one_attached :thumbnail_image  # 일기 썸네일 이미지 (단일)

  # Validations
  validates :title, presence: true
  validates :content, length: { maximum: 10000 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # 사용자가 이 일기의 소유자인지 확인
  def owned_by?(user)
    self.user_id == user.id
  end
end
