# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Folders API", type: :request do
  let(:user) { User.create!(provider: "kakao", uid: "test123", name: "Test User", email: "test@test.com") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  path "/api/v1/folders" do
    get "모든 폴더 조회 (트리 구조)" do
      tags "폴더 관리"
      description "현재 사용자의 모든 폴더를 계층형 트리 구조로 조회합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 folders: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       name: { type: :string },
                       description: { type: :string, nullable: true },
                       created_at: { type: :string, format: "date-time" },
                       updated_at: { type: :string, format: "date-time" },
                       children: { type: :array }
                     }
                   }
                 }
               }

        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        run_test!
      end
    end

    post "폴더 생성" do
      tags "폴더 관리"
      description "새 폴더를 생성합니다"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :folder_params, in: :body, schema: {
        type: :object,
        properties: {
          folder: {
            type: :object,
            properties: {
              name: { type: :string, description: "폴더 이름" },
              parent_id: { type: :integer, nullable: true, description: "부모 폴더 ID (없으면 최상위 폴더)" },
              description: { type: :string, nullable: true, description: "폴더 설명" }
            },
            required: %w[name]
          }
        }
      }

      response "201", "생성 성공" do
        schema type: :object,
               properties: {
                 message: { type: :string },
                 folder: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     name: { type: :string },
                     description: { type: :string, nullable: true },
                     parent_id: { type: :integer, nullable: true },
                     parent_name: { type: :string, nullable: true },
                     path: { type: :string },
                     depth: { type: :integer },
                     is_root: { type: :boolean },
                     children_count: { type: :integer },
                     descendants_count: { type: :integer },
                     created_at: { type: :string, format: "date-time" },
                     updated_at: { type: :string, format: "date-time" }
                   }
                 }
               }

        let(:folder_params) { { folder: { name: "새 폴더", description: "테스트 폴더" } } }
        run_test!
      end

      response "401", "인증 실패" do
        let(:Authorization) { "" }
        let(:folder_params) { { folder: { name: "테스트" } } }
        run_test!
      end
    end
  end

  path "/api/v1/folders/flat" do
    get "모든 폴더 조회 (평면 리스트)" do
      tags "폴더 관리"
      description "현재 사용자의 모든 폴더를 평면 리스트로 조회합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 folders: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       name: { type: :string },
                       description: { type: :string, nullable: true },
                       parent_id: { type: :integer, nullable: true },
                       path: { type: :string },
                       depth: { type: :integer },
                       created_at: { type: :string, format: "date-time" },
                       updated_at: { type: :string, format: "date-time" }
                     }
                   }
                 }
               }

        run_test!
      end
    end
  end

  path "/api/v1/folders/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "폴더 ID"

    get "특정 폴더 상세 조회" do
      tags "폴더 관리"
      description "특정 폴더의 상세 정보를 조회합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 folder: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     name: { type: :string },
                     description: { type: :string, nullable: true },
                     parent_id: { type: :integer, nullable: true },
                     parent_name: { type: :string, nullable: true },
                     path: { type: :string },
                     depth: { type: :integer },
                     is_root: { type: :boolean },
                     children_count: { type: :integer },
                     descendants_count: { type: :integer },
                     created_at: { type: :string, format: "date-time" },
                     updated_at: { type: :string, format: "date-time" }
                   }
                 }
               }

        let(:folder) { user.folders.create!(name: "테스트 폴더") }
        let(:id) { folder.id }
        run_test!
      end

      response "404", "폴더 없음" do
        let(:id) { 99999 }
        run_test!
      end
    end

    patch "폴더 수정" do
      tags "폴더 관리"
      description "폴더 정보를 수정합니다"
      consumes "application/json"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :folder_params, in: :body, schema: {
        type: :object,
        properties: {
          folder: {
            type: :object,
            properties: {
              name: { type: :string },
              parent_id: { type: :integer, nullable: true },
              description: { type: :string, nullable: true }
            }
          }
        }
      }

      response "200", "수정 성공" do
        let(:folder) { user.folders.create!(name: "원래 이름") }
        let(:id) { folder.id }
        let(:folder_params) { { folder: { name: "수정된 이름" } } }
        run_test!
      end

      response "404", "폴더 없음" do
        let(:id) { 99999 }
        let(:folder_params) { { folder: { name: "테스트" } } }
        run_test!
      end
    end

    delete "폴더 삭제" do
      tags "폴더 관리"
      description "폴더를 삭제합니다 (하위 폴더도 함께 삭제됨)"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "삭제 성공" do
        schema type: :object,
               properties: {
                 message: { type: :string }
               }

        let(:folder) { user.folders.create!(name: "삭제할 폴더") }
        let(:id) { folder.id }
        run_test!
      end

      response "404", "폴더 없음" do
        let(:id) { 99999 }
        run_test!
      end
    end
  end

  path "/api/v1/folders/{id}/children" do
    parameter name: :id, in: :path, type: :integer, description: "폴더 ID"

    get "하위 폴더 조회" do
      tags "폴더 관리"
      description "특정 폴더의 직속 하위 폴더들만 조회합니다"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "조회 성공" do
        schema type: :object,
               properties: {
                 folder_id: { type: :integer },
                 folder_name: { type: :string },
                 children: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       name: { type: :string },
                       description: { type: :string, nullable: true },
                       created_at: { type: :string, format: "date-time" },
                       updated_at: { type: :string, format: "date-time" }
                     }
                   }
                 }
               }

        let(:folder) { user.folders.create!(name: "부모 폴더") }
        let(:id) { folder.id }
        run_test!
      end

      response "404", "폴더 없음" do
        let(:id) { 99999 }
        run_test!
      end
    end
  end
end
