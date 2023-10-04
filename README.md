# docker-nvim
A simple neovim plugin for executing commands in running docker containers and redirecting their ouptut into a buffer.

## Installation
```
use {'zotlann/docker-nvim', requires = 'nvim-telescope/telescope.nvim'}
```

## Example configuration
```lua
local docker = require('docker-nvim')

-- set the host to use for selecting running containers and executing commands
-- if unset, uses local machine
-- docker.host = "ssh://user@dockerhost:1234

-- set the workdir to use the current directory when calling docker exec
docker.use_cwd_as_workdir = false

-- set the workdir to use when calling docker exec, if unset use none
-- overrides use_cwd_as_workdir
docker.workdir = ""

-- set the container to use when calling docker exec
-- this can also be set by using docker.pick_container
docker.container = ""

-- opts to be passed to vim.fn.jobstart, by default the opts redirect stdout and stderr to the buffer
-- docker.opts = {}

-- setup keybindings
-- <leader>cp to chose the container using the telescope picker
vim.keymap.set("n", "<leader>cp", docker.pick_conatiner)
-- <leader>cs to chose the container using text input
vim.keymap.set("n", "<leader>cs", function()
	local container = vim.fn.input('Container: ')
	docker.container = container
end)
-- <leader>cb to run build
vim.keymap.set("n", "<leader>cb", function() docker.do_job('./build.sh') end)
-- <leader>cu to run unit tests
vim.keymap.set("n", "<leader>cu", function() docker.do_job('./test.sh --unit') end)
-- <leader>ci to run integration tests
vim.keymap.set("n", "<leader>ci", function() docker.do_job('./test.sh --integration') end)
-- <leader>cc to prompt user for the command that should be run
vim.keymap.set("n", "<leader>cc", function()
	local command = vim.fn.input('Command: ')
	docker.do_job(command)
end)

```

