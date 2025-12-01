require "test_helper"

class FolderTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @other_user = create(:user)
    @root_folder = create(:folder, user: @user, name: "Projects")
    @subfolder = create(:folder, user: @user, name: "Backend", parent: @root_folder)
    @nested_folder = create(:folder, user: @user, name: "API", parent: @subfolder)
    @other_user_folder = create(:folder, user: @other_user, name: "Other Root")
  end

  # Validations
  test "should be valid with valid attributes" do
    folder = build(:folder, user: @user)
    assert folder.valid?
  end

  test "should require name" do
    folder = build(:folder, user: @user, name: nil)
    assert_not folder.valid?
    assert_includes folder.errors[:name], "can't be blank"
  end

  test "should require user" do
    folder = Folder.new(name: "Test Folder")
    assert_not folder.valid?
  end

  test "should validate name length" do
    folder = build(:folder, user: @user, name: "a" * 256)
    assert_not folder.valid?
  end

  # Associations
  test "should belong to user" do
    assert_equal @user, @root_folder.user
  end

  test "should belong to parent folder" do
    assert_equal @root_folder, @subfolder.parent
  end

  test "should have many children" do
    assert_includes @root_folder.children, @subfolder
  end

  test "should cascade delete children" do
    root_id = @root_folder.id
    children_count = @root_folder.children.count
    assert children_count > 0

    @root_folder.destroy
    assert_equal 0, Folder.where(parent_id: root_id).count
  end

  # Hierarchical methods
  test "root? should return true for folders without parent" do
    assert @root_folder.root?
    assert_not @subfolder.root?
  end

  test "has_children? should return true when folder has children" do
    assert @root_folder.has_children?
    assert_not @nested_folder.has_children?
  end

  test "path should return array from root to current folder" do
    path = @nested_folder.path
    assert_equal 3, path.length
    assert_equal @root_folder, path[0]
    assert_equal @subfolder, path[1]
    assert_equal @nested_folder, path[2]
  end

  test "path_string should return formatted path" do
    expected = "Projects > Backend > API"
    assert_equal expected, @nested_folder.path_string
  end

  test "depth should return correct level" do
    assert_equal 0, @root_folder.depth
    assert_equal 1, @subfolder.depth
    assert_equal 2, @nested_folder.depth
  end

  test "descendants should return all nested children" do
    descendants = @root_folder.descendants
    assert_includes descendants, @subfolder
    assert_includes descendants, @nested_folder
    assert_equal 2, descendants.count
  end

  test "subtree should include self and all descendants" do
    subtree = @root_folder.subtree
    assert_includes subtree, @root_folder
    assert_includes subtree, @subfolder
    assert_includes subtree, @nested_folder
    assert_equal 3, subtree.count
  end

  test "ancestors should return all parent folders up to root" do
    ancestors = @nested_folder.ancestors
    assert_equal 2, ancestors.length
    assert_includes ancestors, @root_folder
    assert_includes ancestors, @subfolder
  end

  # Circular reference prevention
  test "should prevent folder from being its own parent" do
    @root_folder.parent_id = @root_folder.id
    assert_not @root_folder.valid?
    assert_includes @root_folder.errors[:parent_id], "cannot be the folder itself"
  end

  test "should prevent circular reference with descendant as parent" do
    @root_folder.parent_id = @nested_folder.id
    assert_not @root_folder.valid?
    assert_includes @root_folder.errors[:parent_id], "cannot be a descendant of this folder"
  end

  # Scopes
  test "root_folders scope should return only root folders" do
    root_folders = Folder.root_folders
    assert_includes root_folders, @root_folder
    assert_not_includes root_folders, @subfolder
  end

  test "for_user scope should return only folders for specific user" do
    user_folders = Folder.for_user(@user.id)
    assert_includes user_folders, @root_folder
    assert_not_includes user_folders, @other_user_folder
  end
end
