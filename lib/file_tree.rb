# frozen_string_literal: true

class FileTree
  def file_icon(file)
    return 'fa-solid fa-lock' if file.missing_read_permissions?

    if file.file_type.audio?
      'fa-regular fa-file-audio'
    elsif file.file_type.compressed?
      'fa-regular fa-file-zipper'
    elsif file.file_type.excel?
      'fa-regular fa-file-excel'
    elsif file.file_type.image?
      'fa-regular fa-file-image'
    elsif file.file_type.pdf?
      'fa-regular fa-file-pdf'
    elsif file.file_type.powerpoint?
      'fa-regular fa-file-powerpoint'
    elsif file.file_type.video?
      'fa-regular fa-file-video'
    elsif file.file_type.word?
      'fa-regular fa-file-word'
    elsif file.read_only?
      'fa-solid fa-lock'
    elsif file.file_type.executable?
      'fa-regular fa-file-code'
    elsif file.file_type.renderable? || file.file_type.csv?
      'fa-regular fa-file-lines'
    else
      'fa-regular fa-file'
    end
  end
  private :file_icon

  def folder_icon
    'fa-regular fa-folder'
  end
  private :folder_icon

  # @param [CodeOcean::File] files The files to be displayed in the tree.
  # @param [String] directories Additional directories to be displayed in the tree
  # @param [Boolean] force_closed Specify whether the tree should be closed by default
  def initialize(files = [], directories = [], force_closed: false)
    # Our tree needs a root node, but we won't display it.
    @root = Tree::TreeNode.new('ROOT')
    @force_closed = force_closed

    files.uniq(&:filepath).each do |file|
      parent = @root
      (file.path || '').split('/').each do |segment|
        node = parent.children.detect {|child| child.name == segment } || parent.add(Tree::TreeNode.new(segment))
        parent = node
      end
      parent.add(Tree::TreeNode.new(file.name_with_extension, file))
    end

    directories.uniq.each do |directory|
      parent = @root
      (directory || '').split('/').each do |segment|
        node = parent.children.detect {|child| child.name == segment } || parent.add(Tree::TreeNode.new(segment))
        parent = node
      end
    end
  end

  def map_to_js_tree(node)
    {
      children: children(node),
      icon: node_icon(node),
      id: node.content.try(:ancestor_id),
      state: {
        disabled: !(node.leaf? && node.content.is_a?(CodeOcean::File)),
        opened: !(node.leaf? || @force_closed),
      },
      text: name(node),
      download_path: node.content.try(:download_path),
      path: node.content.try(:download_path) ? nil : path(node),
    }
  end
  private :map_to_js_tree

  def node_icon(node)
    if node.leaf? && !node.root? && node.content.is_a?(CodeOcean::File)
      file_icon(node.content)
    else
      folder_icon
    end
  end
  private :node_icon

  def children(node)
    if node.children.present? || node.content.is_a?(CodeOcean::File)
      node.children.sort_by {|n| n.name.downcase }.map {|child| map_to_js_tree(child) }
    else
      # Folders added manually should always be expandable and therefore might have children.
      # This allows users to open the folder and get a refreshed view, even if it might be empty.
      true
    end
  end
  private :children

  def name(node)
    # We just need any information that is only present in files retrieved from the runner's file system.
    # In our case, that is the presence of the `privileged_execution` attribute.
    if node.content.is_a?(CodeOcean::File) && !node.content.privileged_execution.nil?
      node.content.name_with_extension_and_size
    else
      node.name
    end
  end
  private :name

  def path(node)
    "#{node.parentage&.reverse&.drop(1)&.map(&:name)&.join('/')}/#{node.name}"
  end
  private :path

  def to_js_tree
    {
      core: {
        data: @root.children.sort_by {|node| node.name.downcase }.map {|child| map_to_js_tree(child) },
      },
    }
  end

  def to_js_tree_in_json
    to_js_tree.to_json
  end
end
