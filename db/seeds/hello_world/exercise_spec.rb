describe 'Exercise' do
  it "outputs 'Hello World" do
    expect(STDOUT).to receive(:puts).with('Hello World')
    require './exercise'
  end
end
