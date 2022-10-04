# frozen_string_literal: true

class FileTree
  def file_icon(file)
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

  def initialize(files = [])
    # Our tree needs a root node, but we won't display it.
    @root = Tree::TreeNode.new('ROOT')

    files.uniq(&:filepath).each do |file|
      parent = @root
      (file.path || '').split('/').each do |segment|
        node = parent.children.detect {|child| child.name == segment } || parent.add(Tree::TreeNode.new(segment))
        parent = node
      end
      parent.add(Tree::TreeNode.new(file.name_with_extension, file))
    end
  end

  def map_to_js_tree(node)
    {
      children: node.children.map {|child| map_to_js_tree(child) },
      icon: node_icon(node),
      id: node.content.try(:ancestor_id),
      state: {
        disabled: !node.leaf?,
        opened: !node.leaf?,
      },
      text: name(node),
      download_path: node.content.try(:download_path),
    }
  end
  private :map_to_js_tree

  def node_icon(node)
    if node.leaf? && !node.root?
      file_icon(node.content)
    else
      folder_icon
    end
  end
  private :node_icon

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

  def to_js_tree
    {
      core: {
        data: @root.children.map {|child| map_to_js_tree(child) },
      },
    }
  end

  def to_js_tree_in_json
    to_js_tree.to_json
  end
end
