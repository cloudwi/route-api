# DiarySerializer - 일기 데이터를 JSON 형식으로 직렬화
# 컨트롤러 전반에서 일관된 일기 데이터 형식을 제공
class DiarySerializer
  # 기본 일기 정보를 JSON으로 변환
  # @param diary [Diary] 직렬화할 일기 객체
  # @param current_user [User, nil] 현재 로그인한 사용자
  # @return [Hash] JSON 형식의 일기 데이터
  def self.serialize(diary, current_user: nil)
    {
      id: diary.id,
      title: diary.title,
      content: diary.content,
      thumbnailImage: diary.thumbnail_image.attached? ? image_url(diary.thumbnail_image) : nil,
      author: {
        id: diary.user.id,
        name: diary.user.name,
        profileImage: diary.user.profile_image
      },
      isOwner: current_user ? diary.owned_by?(current_user) : false,
      sharedUsers: diary.shared_users.map { |user|
        {
          id: user.id,
          name: user.name,
          profileImage: user.profile_image,
          role: diary.diary_users.find_by(user: user)&.role
        }
      },
      createdAt: diary.created_at.iso8601,
      updatedAt: diary.updated_at.iso8601
    }
  end

  # 여러 일기를 한 번에 직렬화
  # @param diaries [Array<Diary>] 직렬화할 일기 배열
  # @param current_user [User, nil] 현재 로그인한 사용자
  # @return [Array<Hash>] JSON 형식의 일기 데이터 배열
  def self.serialize_collection(diaries, current_user: nil)
    diaries.map { |diary| serialize(diary, current_user: current_user) }
  end

  # 간단한 일기 정보 (목록용)
  # @param diary [Diary] 직렬화할 일기 객체
  # @param current_user [User, nil] 현재 로그인한 사용자
  # @return [Hash] 간략한 JSON 형식의 일기 데이터
  def self.serialize_simple(diary, current_user: nil)
    {
      id: diary.id,
      title: diary.title,
      thumbnailImage: diary.thumbnail_image.attached? ? image_url(diary.thumbnail_image) : nil,
      author: {
        id: diary.user.id,
        name: diary.user.name
      },
      isOwner: current_user ? diary.owned_by?(current_user) : false,
      createdAt: diary.created_at.iso8601
    }
  end

  # 간단한 일기 목록 직렬화
  def self.serialize_simple_collection(diaries, current_user: nil)
    diaries.map { |diary| serialize_simple(diary, current_user: current_user) }
  end

  private

  # 이미지 URL 생성
  def self.image_url(image)
    return nil unless image.attached?

    # Rails URL helpers를 사용하여 이미지 URL 생성
    Rails.application.routes.url_helpers.rails_blob_url(image, only_path: false)
  rescue StandardError
    nil
  end
end
