require 'swagger_helper'

RSpec.describe 'api/v1/folders', type: :request do
  path '/api/v1/folders' do
    get('모든 폴더 조회 (트리 구조)') do
      tags '폴더 관리'
      description '현재 사용자의 모든 폴더를 계층형 트리 구조로 조회합니다'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
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
                  created_at: { type: :string, format: :datetime },
                  updated_at: { type: :string, format: :datetime },
                  children: { type: :array }
                }
              }
            }
          }

        run_test!
      end

      response(401, 'unauthorized') do
        run_test!
      end
    end

    post('폴더 생성') do
      tags '폴더 관리'
      description '새 폴더를 생성합니다'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :folder, in: :body, schema: {
        type: :object,
        properties: {
          folder: {
            type: :object,
            properties: {
              name: { type: :string, description: '폴더 이름' },
              parent_id: { type: :integer, nullable: true, description: '부모 폴더 ID (없으면 최상위 폴더)' },
              description: { type: :string, nullable: true, description: '폴더 설명' }
            },
            required: ['name']
          }
        }
      }

      response(201, 'created') do
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
                created_at: { type: :string, format: :datetime },
                updated_at: { type: :string, format: :datetime }
              }
            }
          }

        let(:folder) { { folder: { name: 'Test Folder' } } }

        run_test!
      end

      response(401, 'unauthorized') do
        let(:folder) { { folder: { name: 'Test Folder' } } }
        run_test!
      end
    end
  end

  path '/api/v1/folders/flat' do
    get('모든 폴더 조회 (평면 리스트)') do
      tags '폴더 관리'
      description '현재 사용자의 모든 폴더를 평면 리스트로 조회합니다'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
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
                  created_at: { type: :string, format: :datetime },
                  updated_at: { type: :string, format: :datetime }
                }
              }
            }
          }

        run_test!
      end
    end
  end

  path '/api/v1/folders/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: '폴더 ID'

    get('특정 폴더 상세 조회') do
      tags '폴더 관리'
      description '특정 폴더의 상세 정보를 조회합니다'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
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
                created_at: { type: :string, format: :datetime },
                updated_at: { type: :string, format: :datetime }
              }
            }
          }

        let(:id) { '1' }
        run_test!
      end

      response(404, 'not found') do
        let(:id) { '99999' }
        run_test!
      end
    end

    patch('폴더 수정') do
      tags '폴더 관리'
      description '폴더 정보를 수정합니다'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :folder, in: :body, schema: {
        type: :object,
        properties: {
          folder: {
            type: :object,
            properties: {
              name: { type: :string, description: '폴더 이름' },
              parent_id: { type: :integer, nullable: true, description: '부모 폴더 ID' },
              description: { type: :string, nullable: true, description: '폴더 설명' }
            }
          }
        }
      }

      response(200, 'updated') do
        let(:id) { '1' }
        let(:folder) { { folder: { name: 'Updated Folder' } } }
        run_test!
      end

      response(404, 'not found') do
        let(:id) { '99999' }
        let(:folder) { { folder: { name: 'Updated Folder' } } }
        run_test!
      end
    end

    delete('폴더 삭제') do
      tags '폴더 관리'
      description '폴더를 삭제합니다 (하위 폴더도 함께 삭제됨)'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'deleted') do
        schema type: :object,
          properties: {
            message: { type: :string }
          }

        let(:id) { '1' }
        run_test!
      end

      response(404, 'not found') do
        let(:id) { '99999' }
        run_test!
      end
    end
  end

  path '/api/v1/folders/{id}/children' do
    parameter name: 'id', in: :path, type: :integer, description: '폴더 ID'

    get('하위 폴더 조회') do
      tags '폴더 관리'
      description '특정 폴더의 직속 하위 폴더들만 조회합니다'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
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
                  created_at: { type: :string, format: :datetime },
                  updated_at: { type: :string, format: :datetime }
                }
              }
            }
          }

        let(:id) { '1' }
        run_test!
      end

      response(404, 'not found') do
        let(:id) { '99999' }
        run_test!
      end
    end
  end
end
