# == Schema Information
#
# Table name: folders
#
#  id          :integer          not null, primary key  # 폴더 고유 식별자
#  user_id     :integer          not null               # 폴더 소유자 (User 외래키)
#  name        :string           not null               # 폴더 이름
#  parent_id   :integer                                 # 부모 폴더 ID (자기참조 외래키, NULL이면 최상위 폴더)
#  description :text                                    # 폴더 설명
#  created_at  :datetime         not null               # 레코드 생성 일시
#  updated_at  :datetime         not null               # 레코드 수정 일시
#
# Indexes
#
#  index_folders_on_user_id_and_parent_id  (user_id,parent_id)
#  index_folders_on_name                   (name)
#  index_folders_on_user_id                (user_id)
#  index_folders_on_parent_id              (parent_id)
#

# 폴더 모델 - 계층 구조를 가진 폴더 시스템
# 사용자는 여러 개의 폴더를 가질 수 있고, 폴더는 부모-자식 관계로 중첩될 수 있음
class Folder < ApplicationRecord
  # Associations
  belongs_to :user                                              # 폴더 소유자
  belongs_to :parent, class_name: "Folder", optional: true      # 부모 폴더 (선택적, 없으면 최상위 폴더)
  has_many :children, class_name: "Folder", foreign_key: "parent_id", dependent: :destroy  # 하위 폴더들

  # Validations
  validates :name, presence: true                               # 폴더 이름 필수
  validates :name, length: { minimum: 1, maximum: 255 }         # 폴더 이름 길이 제한
  validate :prevent_circular_reference                          # 순환 참조 방지

  # Scopes
  scope :root_folders, -> { where(parent_id: nil) }             # 최상위 폴더만 조회
  scope :for_user, ->(user_id) { where(user_id: user_id) }     # 특정 사용자의 폴더 조회

  # 최상위 폴더인지 확인
  def root?
    parent_id.nil?
  end

  # 하위 폴더가 있는지 확인
  def has_children?
    children.exists?
  end

  # 폴더의 전체 경로를 배열로 반환 (루트부터 현재 폴더까지)
  # 예: [루트폴더, 중간폴더, 현재폴더]
  def path
    return [ self ] if root?

    parent.path + [ self ]
  end

  # 폴더의 전체 경로를 문자열로 반환
  # 예: "루트폴더 > 중간폴더 > 현재폴더"
  def path_string(separator = " > ")
    path.map(&:name).join(separator)
  end

  # 현재 폴더의 깊이 (계층 레벨) 반환
  # 루트 폴더는 0, 그 하위는 1, 그 하위는 2...
  def depth
    return 0 if root?

    parent.depth + 1
  end

  # 모든 하위 폴더를 재귀적으로 조회 (자식, 손자, 증손자... 모두)
  def descendants
    children.flat_map { |child| [ child ] + child.descendants }
  end

  # 현재 폴더와 모든 하위 폴더를 포함한 배열 반환
  def subtree
    [ self ] + descendants
  end

  # 모든 상위 폴더를 배열로 반환 (부모, 조부모, 증조부모... 루트까지)
  def ancestors
    return [] if root?

    parent.ancestors + [ parent ]
  end

  private

  # 순환 참조 방지 검증
  # 부모 폴더가 자신의 하위 폴더가 되는 것을 방지
  def prevent_circular_reference
    return unless parent_id

    # 부모 폴더가 자기 자신인 경우
    if parent_id == id
      errors.add(:parent_id, "cannot be the folder itself")
      return
    end

    # 부모 폴더가 자신의 하위 폴더인 경우
    if parent && descendants.include?(parent)
      errors.add(:parent_id, "cannot be a descendant of this folder")
    end
  end
end
