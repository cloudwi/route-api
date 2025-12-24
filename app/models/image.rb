# == Schema Information
#
# Table name: images
#
#  id         :integer          not null, primary key
#  user_id    :integer                                    # 업로드한 사용자 (optional)
#  purpose    :string                                     # 이미지 용도
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_images_on_created_at  (created_at)
#  index_images_on_user_id     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

class Image < ApplicationRecord
  belongs_to :user, optional: true  # 로그인 없이도 업로드 가능
  has_one_attached :file  # 실제 이미지 파일

  # Validations
  validate :file_presence
  validate :file_type
  validate :file_size

  private

  def file_presence
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_type
    return unless file.attached?

    acceptable_types = [ "image/png", "image/jpg", "image/jpeg", "image/gif", "image/webp" ]
    unless acceptable_types.include?(file.content_type)
      errors.add(:file, "must be a PNG, JPG, JPEG, GIF, or WebP image")
    end
  end

  def file_size
    return unless file.attached?

    if file.byte_size > 10.megabytes
      errors.add(:file, "must be less than 10MB")
    end
  end

  public

  # 이미지 URL 반환
  def url
    return nil unless file.attached?

    if Rails.env.test?
      Rails.application.routes.url_helpers.rails_blob_url(file, host: "http://localhost:3000")
    else
      Rails.application.routes.url_helpers.rails_blob_url(file, only_path: false)
    end
  rescue StandardError => e
    Rails.logger.error "Image URL generation error: #{e.message}"
    nil
  end
end
