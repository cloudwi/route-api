# == Schema Information
#
# Table name: users
#
#  id            :integer          not null, primary key  # 사용자 고유 식별자
#  provider      :string                                  # OAuth 제공자 (예: kakao, google)
#  uid           :string                                  # OAuth 제공자에서 부여한 사용자 고유 ID
#  email         :string                                  # 사용자 이메일 주소
#  name          :string                                  # 사용자 이름 또는 닉네임
#  profile_image :string                                  # 사용자 프로필 이미지 URL
#  created_at    :datetime         not null              # 레코드 생성 일시
#  updated_at    :datetime         not null              # 레코드 수정 일시
#
# Indexes
#
#  index_users_on_email             (email)
#  index_users_on_provider_and_uid  (provider,uid) UNIQUE
#

# 사용자 정보를 관리하는 모델
# OAuth 인증(Kakao 등)을 통해 생성되며, JWT 인증에 사용됨
class User < ApplicationRecord
  # Associations
  has_many :diaries, dependent: :destroy  # 사용자가 작성한 일기들

  # 커플 관계
  has_many :couple_invitations, foreign_key: :inviter_id, dependent: :destroy  # 보낸 초대

  # 사용자의 커플 찾기
  def couple
    Couple.for_user(id).first
  end

  # 파트너 찾기
  def partner
    couple&.partner_for(self)
  end

  # 커플 관계 확인
  def in_couple?
    couple.present?
  end

  # Validations
  validates :provider, presence: true                                      # OAuth 제공자는 필수
  validates :uid, presence: true, uniqueness: { scope: :provider }         # UID는 제공자별로 고유해야 함
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true  # 이메일 형식 검증 (선택)

  # OmniAuth 인증 데이터로부터 사용자 조회 또는 생성
  # @param auth [OmniAuth::AuthHash] OmniAuth가 제공하는 인증 정보
  # @return [User] 조회되거나 새로 생성된 사용자 객체
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.profile_image = auth.info.image
    end
  end
end
