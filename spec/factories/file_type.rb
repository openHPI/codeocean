FactoryBot.define do
  factory :dot_coffee, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/coffee'
    executable
    file_extension '.coffee'
    indent_size 2
    name 'CoffeeScript'
    singleton_file_type
  end

  factory :dot_gif, class: FileType do
    binary
    created_by_admin
    file_extension '.gif'
    name 'GIF'
    renderable
    singleton_file_type
  end

  factory :dot_html, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/html'
    file_extension '.html'
    indent_size 4
    name 'HTML'
    renderable
    singleton_file_type
  end

  factory :dot_java, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/java'
    executable
    file_extension '.java'
    indent_size 4
    name 'Java'
    singleton_file_type
  end

  factory :dot_jpg, class: FileType do
    binary
    created_by_admin
    file_extension '.jpg'
    name 'JPEG'
    renderable
    singleton_file_type
  end

  factory :dot_js, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/javascript'
    executable
    file_extension '.js'
    indent_size 4
    name 'JavaScript'
    singleton_file_type
  end

  factory :dot_json, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/javascript'
    file_extension '.json'
    indent_size 4
    name 'JSON'
    renderable
    singleton_file_type
  end

  factory :dot_md, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/markdown'
    file_extension '.md'
    indent_size 2
    name 'Markdown'
    singleton_file_type
  end

  factory :dot_mp3, class: FileType do
    binary
    created_by_admin
    file_extension '.mp3'
    name 'MP3'
    renderable
    singleton_file_type
  end

  factory :dot_mp4, class: FileType do
    binary
    created_by_admin
    file_extension '.mp4'
    name 'MPEG-4'
    renderable
    singleton_file_type
  end

  factory :dot_ogg, class: FileType do
    binary
    created_by_admin
    file_extension '.ogg'
    name 'Ogg Vorbis'
    renderable
    singleton_file_type
  end

  factory :dot_png, class: FileType do
    binary
    created_by_admin
    file_extension '.png'
    name 'PNG'
    renderable
    singleton_file_type
  end

  factory :dot_py, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/python'
    executable
    file_extension '.py'
    indent_size 4
    name 'Python'
    singleton_file_type
  end

  factory :dot_rb, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/ruby'
    executable
    file_extension '.rb'
    indent_size 2
    name 'Ruby'
    singleton_file_type
  end

  factory :dot_svg, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/svg'
    file_extension '.svg'
    indent_size 4
    name 'SVG'
    renderable
    singleton_file_type
  end

  factory :dot_sql, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/sql'
    executable
    file_extension '.sql'
    indent_size 4
    name 'SQL'
    singleton_file_type
  end

  factory :dot_txt, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/plain_text'
    file_extension '.txt'
    indent_size 4
    name 'Plain Text'
    renderable
    singleton_file_type
  end

  factory :dot_webm, class: FileType do
    binary
    created_by_admin
    file_extension '.webm'
    name 'WebM'
    renderable
    singleton_file_type
  end

  factory :dot_xml, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/xml'
    file_extension '.xml'
    indent_size 4
    name 'XML'
    renderable
    singleton_file_type
  end

  factory :makefile, class: FileType do
    created_by_admin
    editor_mode 'ace/mode/makefile'
    executable
    indent_size 2
    name 'Makefile'
    singleton_file_type
  end

  [:binary, :executable, :renderable].each do |attribute|
    trait(attribute) { send(attribute, true) }
  end

  trait :singleton_file_type do
    initialize_with { FileType.where(attributes).first_or_create }
  end
end
