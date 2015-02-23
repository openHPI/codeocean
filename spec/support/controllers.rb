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
    expect([response.content_type, response.headers['Content-Type']]).to include(content_type)
  end
end

def expect_flash_message(type, message = nil)
  it 'displays a flash message' do
    if message
      expect(flash[type]).to eq(message.is_a?(String) ? message : I18n.t(message))
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

def expect_status(status)
  it "responds with status #{status}" do
    expect(response.status).to eq(status)
  end
end

def expect_template(template)
  it "renders the '#{template}' template" do
    expect(controller).to render_template(template)
  end
end

def obtain_object(value)
  case value
  when Proc
    value.call
  when Symbol
    send(value)
  else
    value
  end
end
