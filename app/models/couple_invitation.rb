# == Schema Information
#
# Table name: couple_invitations
#
#  id         :integer          not null, primary key
#  inviter_id :integer          not null                # 초대를 보낸 사용자
#  token      :string           not null                # 초대 링크 토큰
#  expires_at :datetime         not null                # 초대 만료 시간
#  used       :boolean          default(FALSE), not null # 초대 사용 여부
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_couple_invitations_on_expires_at  (expires_at)
#  index_couple_invitations_on_inviter_id  (inviter_id)
#  index_couple_invitations_on_token       (token) UNIQUE
#
# Foreign Keys
#
#  inviter_id  (inviter_id => users.id)
#

class CoupleInvitation < ApplicationRecord
  belongs_to :inviter, class_name: "User"

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :valid, -> { where(used: false).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  # 초대가 유효한지 확인
  def valid?
    !used && expires_at > Time.current
  end

  # 초대를 사용 처리
  def mark_as_used!
    update!(used: true)
  end

  private

  # 고유한 토큰 생성
  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  # 만료 시간 설정 (24시간)
  def set_expiration
    self.expires_at ||= 24.hours.from_now
  end
end
