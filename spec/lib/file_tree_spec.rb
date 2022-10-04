# frozen_string_literal: true

require 'rails_helper'

describe FileTree do
  let(:file_tree) { described_class.new }

  describe '#file_icon' do
    let(:file_icon) { file_tree.send(:file_icon, file) }

    context 'with a media file' do
      context 'with an audio file' do
        let(:file) { build(:file, file_type: build(:dot_mp3)) }

        it 'is an audio file icon' do
          expect(file_icon).to include('fa-file-audio')
          expect(file_icon).to include('fa-regular')
        end
      end

      context 'with an image file' do
        let(:file) { build(:file, file_type: build(:dot_jpg)) }

        it 'is an image file icon' do
          expect(file_icon).to include('fa-file-image')
          expect(file_icon).to include('fa-regular')
        end
      end

      context 'with a video file' do
        let(:file) { build(:file, file_type: build(:dot_mp4)) }

        it 'is a video file icon' do
          expect(file_icon).to include('fa-file-video')
          expect(file_icon).to include('fa-regular')
        end
      end
    end

    context 'with other files' do
      context 'with a read-only file' do
        let(:file) { build(:file, read_only: true) }

        it 'is a lock icon' do
          expect(file_icon).to include('fa-lock')
          expect(file_icon).to include('fa-solid')
        end
      end

      context 'with an executable file' do
        let(:file) { build(:file, file_type: build(:dot_py)) }

        it 'is a code file icon' do
          expect(file_icon).to include('fa-file-code')
          expect(file_icon).to include('fa-regular')
        end
      end

      context 'with a renderable file' do
        let(:file) { build(:file, file_type: build(:dot_svg)) }

        it 'is a text file icon' do
          expect(file_icon).to include('fa-file-lines')
          expect(file_icon).to include('fa-regular')
        end
      end

      context 'with all other files' do
        let(:file) { build(:file, file_type: build(:dot_md)) }

        it 'is a generic file icon' do
          expect(file_icon).to include('fa-file')
          expect(file_icon).to include('fa-regular')
        end
      end
    end
  end

  describe '#folder_icon' do
    it 'is a folder icon' do
      expect(file_tree.send(:folder_icon)).to include('fa-folder')
      expect(file_tree.send(:folder_icon)).to include('fa-regular')
    end
  end

  describe '#initialize' do
    let(:file_tree) { described_class.new(files) }
    let(:files) { build_list(:file, 10, context: nil, path: 'foo/bar/baz') }

    it 'creates a root node' do
      # Instead of checking #initialize on the parent, we validate #set_as_root!
      expect(Tree::TreeNode).to receive(:new).and_call_original.at_least(:once)
      file_tree.send(:initialize)
    end

    it 'creates tree nodes for every file' do
      expect(file_tree.instance_variable_get(:@root).select(&:content).map(&:content)).to eq(files)
    end

    it 'creates tree nodes for intermediary path segments' do
      expect(file_tree.instance_variable_get(:@root).reject(&:content).reject(&:root?).map(&:name)).to eq(files.first.path.split('/'))
    end
  end

  describe '#map_to_js_tree' do
    let(:file) { build(:file) }
    let(:js_tree) { file_tree.send(:map_to_js_tree, node) }
    let!(:leaf) { root.add(Tree::TreeNode.new('', file)) }
    let(:root) { Tree::TreeNode.new('', file) }

    context 'with a leaf node' do
      let(:node) { leaf }

      it 'produces the required attributes' do
        expect(js_tree).to include(:icon, :id, :text)
      end

      it 'is enabled' do
        expect(js_tree[:state][:disabled]).to be false
      end

      it 'is closed' do
        expect(js_tree[:state][:opened]).to be false
      end
    end

    context 'with a non-leaf node' do
      let(:node) { root }

      it "traverses the node's children" do
        node.children.each do |child|
          expect(file_tree).to receive(:map_to_js_tree).at_least(:once).with(child).and_call_original
        end
        js_tree
      end

      it 'produces the required attributes' do
        expect(js_tree).to include(:icon, :id, :text)
      end

      it 'is disabled' do
        expect(js_tree[:state][:disabled]).to be true
      end

      it 'is opened' do
        expect(js_tree[:state][:opened]).to be true
      end
    end
  end

  describe '#node_icon' do
    let(:node_icon) { file_tree.send(:node_icon, node) }
    let(:root) { Tree::TreeNode.new('') }

    context 'with the root node' do
      let(:node) { root }

      it 'is a folder icon' do
        expect(node_icon).to eq(file_tree.send(:folder_icon))
      end
    end

    context 'with leaf nodes' do
      let(:node) { root.add(Tree::TreeNode.new('', CodeOcean::File.new)) }

      it 'is a file icon' do
        expect(file_tree).to receive(:file_icon)
        node_icon
      end
    end

    context 'with intermediary nodes' do
      let(:node) do
        root.add(Tree::TreeNode.new('').tap {|node| node.add(Tree::TreeNode.new('')) })
      end

      it 'is a folder icon' do
        expect(node_icon).to eq(file_tree.send(:folder_icon))
      end
    end
  end

  describe '#to_js_tree_in_json' do
    let(:js_tree) { file_tree.to_js_tree_in_json }

    it 'returns a String' do
      expect(js_tree).to be_a(String)
    end

    context 'without any file' do
      it 'produces the required JSON format' do
        expect(JSON.parse(js_tree).deep_symbolize_keys).to eq(core: {data: []})
      end
    end

    context 'with files' do
      let(:files) { build_list(:file, 10, context: nil, path: 'foo/bar/baz') }
      let(:file_tree) { described_class.new(files) }
      let(:js_tree) { file_tree.to_js_tree_in_json }

      it 'produces the required JSON format with a file' do
        # We ignore the root node and only use the children here
        child_tree = file_tree.send(:map_to_js_tree, file_tree.instance_variable_get(:@root).children.first)
        expect(JSON.parse(js_tree).deep_symbolize_keys).to eq(core: {data: [child_tree]})
      end
    end
  end
end
