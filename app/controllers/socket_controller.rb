class SocketController < ApplicationController
    include Tubesock::Hijack

    def authorize!
        true
    end
    private :authorize!

    def docker
        hijack do |tubesock|
            Thread.new { EventMachine.run } unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?

            container_id = params[:id]
            socket = Faye::WebSocket::Client.new('ws://localhost:2375/containers/' + container_id + '/attach/ws?stderr=1&stdout=1&stream=1&stdin=1', [], :headers => { 'Origin' => 'http://localhost'}
            )

            socket.on :error do |event|
                puts "Something wrent really wrong: " + event.message
            end

            socket.on :open do |event|
                puts "Created docker socket."
            end

            socket.on :message do |event|
                puts "Server sending: " + event.data
                tubesock.send_data event.data
            end

            tubesock.onmessage do |data|
                puts "Client sending: " + data
                res = socket.send data
                if res == false
                    puts "Something is wrong."
                end
            end
        end
        authorize!
    # ensure
    #     render(nothing: true)
    end

    def stuff
        container = Docker::Container.create('Image' => 'webpython', 'Cmd' => ['/bin/bash'], 'OpenStdin' => true, 'StdinOnce' => true)
        container.tap(&:start).attach(stream: true, stdin: $stdin, stdout: true, stderr: true, tty: true){ |stream, chunk|
                tubesock.send chunk
        }
    end
end
