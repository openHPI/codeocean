Local setup
===========

1. `git checkout webpython-hybrid`
2. Make sure to install all dependencies and migrations:

        rake db:migrate
        bundle install

3. Create a new docker image containing the Turtle library and the i/o wrapper:

        cd webpython
        docker build -t IMAGE_NAME .

4. Configure your Docker host at `config/docker.yml.erb`. Make sure to add a websocket host, for example like this (this is probably different for you):

        host: tcp://localhost:2375
        ws_host: ws://localhost:2375

5. Run the CodeOcean server with `rails s -p 7000`

6. Login with admin@example.org (pw: admin) and create a new execution environment picking the newly created Docker image from the dropdown. Set the initial command to:

        cd /usr/lib/python3.4 && python3 webpython.py

7. Create a new exercise for the newly created execution environment with an arbritrary main file.
8. Implement the exercise. The code below can be used as an example to see the canvas and I/O in action:

        import turtle
        wn = turtle.Screen()
        alex = turtle.Turtle()

        # i/o test
        print("hello!")
        print("please enter your name")
        name = input()
        print("your name is", name)

        # canvas test
        alex.forward(50)
        alex.right(90)
        alex.forward(30)
        alex.right(90)
        alex.forward(30)

        wn.mainloop()

