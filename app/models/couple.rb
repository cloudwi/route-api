# == Schema Information
#
# Table name: couples
#
#  id         :integer          not null, primary key
#  user1_id   :integer          not null                # 커플의 첫 번째 사용자
#  user2_id   :integer          not null                # 커플의 두 번째 사용자
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_couples_on_user1_id                (user1_id)
#  index_couples_on_user1_id_and_user2_id   (user1_id,user2_id) UNIQUE
#  index_couples_on_user2_id                (user2_id)
#
# Foreign Keys
#
#  user1_id  (user1_id => users.id)
#  user2_id  (user2_id => users.id)
#

class Couple < ApplicationRecord
  belongs_to :user1, class_name: "User"
  belongs_to :user2, class_name: "User"

  validates :user1_id, presence: true
  validates :user2_id, presence: true
  validate :users_must_be_different
  validate :user1_must_be_smaller

  # 특정 사용자가 포함된 커플 찾기
  scope :for_user, ->(user_id) { where("user1_id = ? OR user2_id = ?", user_id, user_id) }

  # 사용자의 파트너 찾기
  def partner_for(user)
    if user.id == user1_id
      user2
    elsif user.id == user2_id
      user1
    else
      nil
    end
  end

  # 사용자가 이 커플에 속해있는지 확인
  def includes_user?(user)
    user1_id == user.id || user2_id == user.id
  end

  private

  def users_must_be_different
    if user1_id == user2_id
      errors.add(:base, "Cannot create a couple with the same user")
    end
  end

  # user1_id가 항상 user2_id보다 작도록 보장 (중복 방지)
  def user1_must_be_smaller
    if user1_id && user2_id && user1_id > user2_id
      errors.add(:base, "user1_id must be less than user2_id")
    end
  end
end
