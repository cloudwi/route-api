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
  has_many :diary_users, dependent: :destroy  # 공유된 사용자들
  has_many :shared_users, through: :diary_users, source: :user  # 공유된 사용자 목록
  has_one_attached :thumbnail_image  # 일기 썸네일 이미지 (단일)

  # Validations
  validates :title, presence: true
  validates :content, length: { maximum: 10000 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # 특정 사용자가 접근 가능한 일기들 (본인 작성 + 공유받은 일기)
  scope :accessible_by, ->(user) {
    left_joins(:diary_users)
      .where("diaries.user_id = :user_id OR diary_users.user_id = :user_id", user_id: user.id)
      .distinct
  }

  # 일기를 특정 사용자와 공유
  # @param user [User] 공유할 사용자
  # @param role [String] 권한 (viewer, editor)
  def share_with(user, role: "viewer")
    diary_users.find_or_create_by(user: user) do |diary_user|
      diary_user.role = role
    end
  end

  # 특정 사용자와의 공유 해제
  def unshare_with(user)
    diary_users.find_by(user: user)&.destroy
  end

  # 사용자가 이 일기의 소유자인지 확인
  def owned_by?(user)
    self.user_id == user.id
  end

  # 사용자가 이 일기에 접근 가능한지 확인
  def accessible_by?(user)
    owned_by?(user) || shared_users.include?(user)
  end
end
