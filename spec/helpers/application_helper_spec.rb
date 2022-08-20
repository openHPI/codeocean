# frozen_string_literal: true

require 'rails_helper'

describe ApplicationHelper do
  describe '#code_tag' do
    context 'with code' do
      let(:code) { 'puts 42' }
      let(:html) { code_tag(code) }

      it "builds a 'pre' tag" do
        expect(html).to have_css('pre code')
      end

      it 'contains the code' do
        expect(html).to have_text(code)
      end
    end

    context 'without code' do
      it 'calls #empty' do
        expect(code_tag('')).to eq(empty)
      end
    end
  end

  describe '#empty' do
    it "builds an 'i' tag" do
      expect(empty).to have_css('i.empty.fa-solid.fa-minus')
    end
  end

  describe '#label_column' do
    it 'translates the label' do
      expect(I18n).to receive(:translate).at_least(:once)
      label_column('foo')
    end
  end

  describe '#no' do
    it "builds an 'i' tag" do
      expect(no).to have_css('i.fa-solid.fa-xmark')
    end
  end

  describe '#progress_bar' do
    let(:html) { progress_bar(value) }

    context 'with a value' do
      let(:value) { 42 }

      it "builds nested 'div' tags" do
        expect(html).to have_css('div.progress div.progress-bar')
      end

      it 'assigns the correct text' do
        expect(html).to have_text("#{value}%")
      end

      it 'uses the correct width' do
        expect(html).to have_css("div.progress-bar[style='width: 42%;']")
      end
    end

    context 'without a value' do
      let(:value) { nil }

      it 'does not raise an error' do
        expect { html }.not_to raise_error
      end

      it 'assigns the correct classes' do
        expect(html).to have_css('div.disabled.progress div.progress-bar')
      end

      it 'uses the correct width' do
        expect(html).to have_css("div.progress-bar[style='width: 0%;']")
      end
    end
  end

  describe '#row' do
    let(:html) { row(label: 'foo', value: 42) }

    it "builds nested 'div' tags" do
      expect(html).to have_css('div.attribute-row.row div.col-md-3 + div.col-md-9')
    end
  end

  describe '#value_column' do
    context 'without a value' do
      let(:html) { value_column('') }

      it "builds a 'div' tag" do
        expect(html).to have_css('div')
      end

      it 'calls #empty' do
        expect(html).to include(empty)
      end
    end

    context "with a 'false' value" do
      let(:html) { value_column(false) }

      it "builds a 'div' tag" do
        expect(html).to have_css('div')
      end

      it 'calls #no' do
        expect(html).to include(no)
      end
    end

    context "with a 'true' value" do
      let(:html) { value_column(true) }

      it "builds a 'div' tag" do
        expect(html).to have_css('div')
      end

      it 'calls #yes' do
        expect(html).to include(yes)
      end
    end

    context 'with a non-boolean value' do
      let(:html) { value_column(value) }
      let(:value) { [42] }

      it "builds a 'div' tag" do
        expect(html).to have_css('div')
      end

      it "uses the value's string representation" do
        expect(value).to receive(:to_s)
        html
      end
    end
  end

  describe '#yes' do
    it "builds an 'i' tag" do
      expect(yes).to have_css('i.fa-solid.fa-check')
    end
  end
end
