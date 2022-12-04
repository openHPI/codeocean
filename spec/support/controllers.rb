# frozen_string_literal: true

def expect_assigns(pairs)
  pairs.each do |key, value|
    it "assigns @#{key}" do
      if value.is_a?(Class)
        expect(assigns(key)).to be_a(value)
      else
        object = obtain_object(value)
        if object.is_a?(ActiveRecord::Relation) || object.is_a?(Array)
          expect(assigns(key)).to match_array(object)
        else
          expect(assigns(key)).to eq(object)
        end
      end
    end
  end
end

def expect_content_type(content_type)
  it "responds with content type '#{content_type}'" do
    expect([response.media_type, response.headers['Content-Type']]).to include(content_type)
  end
end

def expect_flash_message(type, message = nil)
  it 'displays a flash message' do
    if message
      expect(flash[type]).to eq(obtain_message(message))
    else
      expect(flash[type]).to be_present
    end
  end
end

def expect_json
  expect_content_type('application/json')
end

def expect_redirect(path = nil)
  if path
    it "redirects to #{path}" do
      expect(controller).to redirect_to(path)
    end
  else
    it 'performs a redirect' do
      expect(response).to be_redirect
    end
  end
end

def expect_http_status(status)
  it "responds with status #{status}" do
    expect(response).to have_http_status(status)
  end
end

def expect_template(template)
  it "renders the '#{template}' template" do
    expect(controller).to render_template(template)
  end
end

def obtain_object(object)
  case object
    when Proc
      object.call
    when Symbol
      send(object)
    else
      object
  end
end
private :obtain_object

def obtain_message(object)
  if object.is_a?(String)
    object
  elsif I18n.exists?(object)
    I18n.t(object)
  else
    send(object)
  end
end
private :obtain_message
