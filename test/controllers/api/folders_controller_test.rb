require "test_helper"

class Api::FoldersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @other_user = create(:user)
    @root_folder = create(:folder, user: @user, name: "Root Folder")
    @subfolder = create(:folder, user: @user, name: "Subfolder", parent: @root_folder)
    @nested_folder = create(:folder, user: @user, name: "Nested Folder", parent: @subfolder)
    @other_user_folder = create(:folder, user: @other_user, name: "Other User Folder")
    @token = JsonWebToken.encode(user_id: @user.id)
  end

  def auth_headers
    { "Authorization" => "Bearer #{@token}" }
  end

  # Index action
  test "should get index with tree structure" do
    get api_v1_folders_url, headers: auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert json["folders"].is_a?(Array)
  end

  test "should require authentication for index" do
    get api_v1_folders_url
    assert_response :unauthorized
  end

  # Flat action
  test "should get flat list of folders" do
    get flat_api_v1_folders_url, headers: auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert json["folders"].is_a?(Array)
  end

  # Show action
  test "should show folder" do
    get api_v1_folder_url(@root_folder), headers: auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @root_folder.id, json["folder"]["id"]
    assert_equal @root_folder.name, json["folder"]["name"]
  end

  test "should not show other user's folder" do
    get api_v1_folder_url(@other_user_folder), headers: auth_headers
    assert_response :not_found
  end

  test "should return 404 for non-existent folder" do
    get api_v1_folder_url(id: 99999), headers: auth_headers
    assert_response :not_found
  end

  # Children action
  test "should get folder children" do
    get children_api_v1_folder_url(@root_folder), headers: auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @root_folder.id, json["folder_id"]
    assert json["children"].is_a?(Array)
  end

  # Create action
  test "should create root folder" do
    assert_difference("Folder.count") do
      post api_v1_folders_url,
           params: { folder: { name: "New Root Folder", description: "Test" } },
           headers: auth_headers
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Root Folder", json["folder"]["name"]
    assert json["folder"]["is_root"]
  end

  test "should create subfolder" do
    assert_difference("Folder.count") do
      post api_v1_folders_url,
           params: { folder: { name: "New Subfolder", parent_id: @root_folder.id } },
           headers: auth_headers
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Subfolder", json["folder"]["name"]
    assert_equal @root_folder.id, json["folder"]["parent_id"]
  end

  test "should not create folder without name" do
    assert_no_difference("Folder.count") do
      post api_v1_folders_url,
           params: { folder: { name: "" } },
           headers: auth_headers
    end

    assert_response :unprocessable_entity
  end

  test "should not create folder with other user's parent" do
    assert_no_difference("Folder.count") do
      post api_v1_folders_url,
           params: { folder: { name: "Test", parent_id: @other_user_folder.id } },
           headers: auth_headers
    end

    assert_response :not_found
  end

  test "should require authentication to create folder" do
    assert_no_difference("Folder.count") do
      post api_v1_folders_url,
           params: { folder: { name: "Test" } }
    end

    assert_response :unauthorized
  end

  # Update action
  test "should update folder" do
    patch api_v1_folder_url(@subfolder),
          params: { folder: { name: "Updated Name" } },
          headers: auth_headers

    assert_response :success
    @subfolder.reload
    assert_equal "Updated Name", @subfolder.name
  end

  test "should update folder parent" do
    patch api_v1_folder_url(@nested_folder),
          params: { folder: { parent_id: @root_folder.id } },
          headers: auth_headers

    assert_response :success
    @nested_folder.reload
    assert_equal @root_folder.id, @nested_folder.parent_id
  end

  test "should not update with invalid data" do
    patch api_v1_folder_url(@subfolder),
          params: { folder: { name: "" } },
          headers: auth_headers

    assert_response :unprocessable_entity
  end

  test "should not update other user's folder" do
    patch api_v1_folder_url(@other_user_folder),
          params: { folder: { name: "Hacked" } },
          headers: auth_headers

    assert_response :not_found
  end

  test "should not update with other user's parent" do
    patch api_v1_folder_url(@subfolder),
          params: { folder: { parent_id: @other_user_folder.id } },
          headers: auth_headers

    assert_response :not_found
  end

  # Destroy action
  test "should destroy folder" do
    folder = create(:folder, user: @user, name: "To Delete")

    assert_difference("Folder.count", -1) do
      delete api_v1_folder_url(folder), headers: auth_headers
    end

    assert_response :success
  end

  test "should destroy folder and all descendants" do
    initial_count = Folder.where(user: @user).count
    descendants_count = @root_folder.descendants.count

    delete api_v1_folder_url(@root_folder), headers: auth_headers

    assert_response :success
    assert_equal initial_count - descendants_count - 1, Folder.where(user: @user).count
  end

  test "should not destroy other user's folder" do
    assert_no_difference("Folder.count") do
      delete api_v1_folder_url(@other_user_folder), headers: auth_headers
    end

    assert_response :not_found
  end
end
