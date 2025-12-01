module Api
  module V1
    # 폴더 관리 API 컨트롤러
    # 사용자의 계층형 폴더 구조를 관리하는 CRUD 엔드포인트 제공
    class FoldersController < ApplicationController
      before_action :require_login # 모든 액션에 로그인 필수
      before_action :set_folder, only: [ :show, :update, :destroy, :children ]

      # GET /api/v1/folders
      # 현재 사용자의 모든 폴더 조회 (트리 구조로 반환)
      def index
        @folders = current_user.folders.root_folders.includes(:children)

        render json: {
          folders: @folders.map { |folder| folder_tree_json(folder) }
        }
      end

      # GET /api/v1/folders/flat
      # 현재 사용자의 모든 폴더를 평면 리스트로 조회
      def flat
        @folders = current_user.folders.includes(:parent)

        render json: {
          folders: @folders.map { |folder| folder_with_path_json(folder) }
        }
      end

      # GET /api/v1/folders/:id
      # 특정 폴더의 상세 정보 조회
      def show
        render json: {
          folder: folder_detail_json(@folder)
        }
      end

      # GET /api/v1/folders/:id/children
      # 특정 폴더의 직속 하위 폴더들만 조회
      def children
        @children = @folder.children

        render json: {
          folder_id: @folder.id,
          folder_name: @folder.name,
          children: @children.map { |child| folder_json(child) }
        }
      end

      # POST /api/v1/folders
      # 새 폴더 생성
      # 파라미터:
      #   - name: 폴더 이름 (필수)
      #   - parent_id: 부모 폴더 ID (선택, 없으면 최상위 폴더)
      #   - description: 폴더 설명 (선택)
      def create
        @folder = current_user.folders.build(folder_params)

        # parent_id가 제공된 경우, 해당 폴더가 현재 사용자 소유인지 검증
        if @folder.parent_id.present?
          parent_folder = current_user.folders.find_by(id: @folder.parent_id)
          unless parent_folder
            render json: { error: "Parent folder not found or not accessible" }, status: :not_found
            return
          end
        end

        if @folder.save
          render json: {
            message: "Folder created successfully",
            folder: folder_detail_json(@folder)
          }, status: :created
        else
          render json: { errors: @folder.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/folders/:id
      # 폴더 정보 수정
      # 파라미터:
      #   - name: 폴더 이름 (선택)
      #   - parent_id: 부모 폴더 ID (선택)
      #   - description: 폴더 설명 (선택)
      def update
        # parent_id 변경 시, 새 부모 폴더가 현재 사용자 소유인지 검증
        if folder_params[:parent_id].present?
          new_parent = current_user.folders.find_by(id: folder_params[:parent_id])
          unless new_parent
            render json: { error: "Parent folder not found or not accessible" }, status: :not_found
            return
          end
        end

        if @folder.update(folder_params)
          render json: {
            message: "Folder updated successfully",
            folder: folder_detail_json(@folder)
          }
        else
          render json: { errors: @folder.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/folders/:id
      # 폴더 삭제 (하위 폴더도 함께 삭제됨)
      def destroy
        folder_name = @folder.name
        descendants_count = @folder.descendants.count

        @folder.destroy

        render json: {
          message: "Folder '#{folder_name}' and #{descendants_count} subfolder(s) deleted successfully"
        }
      end

      private

      # 현재 사용자의 폴더 중에서 ID로 조회
      def set_folder
        @folder = current_user.folders.find_by(id: params[:id])
        unless @folder
          render json: { error: "Folder not found" }, status: :not_found
        end
      end

      # Strong parameters
      def folder_params
        params.require(:folder).permit(:name, :parent_id, :description)
      end

      # JSON 직렬화 헬퍼 메서드들

      # 기본 폴더 정보 (ID, 이름, 설명만)
      def folder_json(folder)
        {
          id: folder.id,
          name: folder.name,
          description: folder.description,
          created_at: folder.created_at,
          updated_at: folder.updated_at
        }
      end

      # 경로 정보 포함
      def folder_with_path_json(folder)
        folder_json(folder).merge(
          parent_id: folder.parent_id,
          path: folder.path_string,
          depth: folder.depth
        )
      end

      # 상세 정보 (부모, 자식 개수, 경로 등 모든 정보)
      def folder_detail_json(folder)
        folder_json(folder).merge(
          parent_id: folder.parent_id,
          parent_name: folder.parent&.name,
          path: folder.path_string,
          depth: folder.depth,
          is_root: folder.root?,
          children_count: folder.children.count,
          descendants_count: folder.descendants.count
        )
      end

      # 트리 구조로 직렬화 (재귀적으로 하위 폴더 포함)
      def folder_tree_json(folder)
        folder_json(folder).merge(
          children: folder.children.map { |child| folder_tree_json(child) }
        )
      end
    end
  end
end
