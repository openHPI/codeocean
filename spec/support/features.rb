# frozen_string_literal: true

def expect_forbidden_path(path_name)
  it "forbids to access the #{path_name.to_s.split('_').join(' ')}" do
    visit(send(path_name))
    expect_path('/')
  end
end

def expect_path(path)
  expect(URI.parse(current_url).path).to eq(path)
end

def expect_permitted_path(path_name)
  it "permits to access the #{path_name.to_s.split('_').join(' ')}" do
    visit(send(path_name))
    expect_path(send(path_name))
  end
end
