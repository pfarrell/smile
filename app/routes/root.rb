class App < Sinatra::Application
  get "/" do
    haml :index, locals: {messages: Message, errors: Error}
  end
end
