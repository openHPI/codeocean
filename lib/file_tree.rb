class FileTree < Tree::TreeNode
  def file_icon(file)
    if file.file_type.audio?
      'fa fa-file-audio-o'
    elsif file.file_type.image?
      'fa fa-file-image-o'
    elsif file.file_type.video?
      'fa fa-file-video-o'
    elsif file.read_only?
      'fa fa-lock'
    elsif file.file_type.executable?
      'fa fa-file-code-o'
    elsif file.file_type.renderable?
      'fa fa-file-text-o'
    else
      'fa fa-file-o'
    end
  end
  private :file_icon

  def folder_icon
    'fa fa-folder-o'
  end
  private :folder_icon

  def initialize(files = [])
    super(root_label)
    files.uniq{|f| f.name_with_extension}.each do |file|
      parent = self
      (file.path || '').split('/').each do |segment|
        node = parent.children.detect { |child| child.name == segment } || parent.add(Tree::TreeNode.new(segment))
        parent = node
      end
      parent.add(Tree::TreeNode.new(file.name_with_extension, file))
    end
  end

  def map_to_js_tree(node)
    {
      children: node.children.map { |child| map_to_js_tree(child) },
      icon: node_icon(node),
      id: node.content.try(:ancestor_id),
      state: {
        disabled: !node.is_leaf?,
        opened: !node.is_leaf?
      },
      text: node.name
    }
  end
  private :map_to_js_tree

  def node_icon(node)
    if node.is_root?
      folder_icon
    elsif node.is_leaf?
      file_icon(node.content)
    else
      folder_icon
    end
  end
  private :node_icon

  def root_label
    I18n.t('exercises.editor_file_tree.file_root')
  end
  private :root_label

  def to_js_tree
    {
      core: {
        data: map_to_js_tree(self)
      }
    }.to_json
  end
end
