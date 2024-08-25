# Devcontainer setup

With the devcontainer-based setup, you won't need to (manually) install CodeOcean and all dependencies on your local instance. Instead, a Docker setup containing all requirements will be configured. The development environment is defined in the `.devcontainer` repository folder and will be applied when you open the project in a supported editor or IDE.

Please note that the devcontainer setup does not provide support for any Runner Management for executing code submissions. You can still use the devcontainer setup for everything else, but will need to set up a Runner Management separately if you want to execute code submissions.

## Local setup

In order to run the devcontainer locally, you need to have Docker installed on your machine. You can find the installation instructions for your operating system on the [official Docker website](https://docs.docker.com/get-docker/). Then, you'll need an editor or IDE that supports devcontainers. We recommend [Visual Studio Code](https://code.visualstudio.com/),[RubyMine](https://www.jetbrains.com/ruby/), [IntelliJ IDEA](https://www.jetbrains.com/idea/).

### Clone the repository:

You may either clone the repository via SSH (recommended) or HTTPS (hassle-free for read operations). If you haven't set up GitHub with your SSH key, you might follow [their official guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

**SSH (recommended, requires initial setup):**
```shell
git clone git@github.com:openHPI/codeocean.git
```

**HTTPS (easier for read operations):**
```shell
git clone https://github.com/openHPI/codeocean.git
```

### Open the project in your editor or IDE:

Open the project in your editor or IDE to get started:

**Visual Studio Code:**
```shell
code codeocean
```

**RubyMine:**
```shell
rubymine codeocean
```

**IntelliJ IDEA:**
```shell
idea codeocean
```

### Install the recommended extensions:

When you open the project in an supported editor or IDE, you'll be prompted to install the recommended extension(s) for support with devcontainers. Click on "Install" to install the recommended extensions.

### Start the devcontainer:

After you've installed the recommended extension(s), you can start the devcontainer by a simple click.

**Visual Studio Code:**
Click on the blue "Reopen in Container" button in the bottom right corner of your editor. [More information](https://code.visualstudio.com/docs/devcontainers/tutorial).

**RubyMine:** / **IntelliJ IDEA:**
Open the file `.devcontainer/devcontainer.json` and click on the blue Docker icon in the top left corner of your editor. More information for [RubyMine](https://www.jetbrains.com/help/ruby/connect-to-devcontainer.html#create_dev_container_inside_ide) or [IntelliJ IDEA](https://www.jetbrains.com/help/idea/connect-to-devcontainer.html#create_dev_container_inside_ide).

# Start CodeOcean

When developing with the devcontainer, you can run CodeOcean in the same way as you would on your local machine. The only difference is that you're running it inside the devcontainer. You can find more information on how to run CodeOcean in the [LOCAL_SETUP.md](LOCAL_SETUP.md#start-codeocean). All ports are forwarded to your local machine, so you can access CodeOcean in your browser as usual.
