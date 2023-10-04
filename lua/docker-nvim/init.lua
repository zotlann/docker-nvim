local has_telescope, telescope = pcall(require, 'telescope')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local themes = require('telescope.themes')
local finders = require('telescope.finders')
local telescope_config = require('telescope.config')
local pickers = require('telescope.pickers')

if not has_telescope then
	error('docker-nvim requires nvim-telescope/telescope.nvim')
end

local M = {}

-- buffer id for the the buffer we write the job output to
local bufnr = 0
-- container to be used for docker exec
M.container = ""
-- opts for the jobstart, can be overridden if desired
M.opts = {}
-- whether or not to use vim.fn.getcwd() as the docker exec workdir
M.use_cwd_as_workdir = false
-- docker host to use
M.host = ""
-- dir to use as the docker exec workdir, override M.use_cwd_as_workdir if set
M.workdir = ""

-- callback to redirect job data to buffer
local function redirect(_, data,  _)
	vim.api.nvim_buf_set_lines(bufnr , -2, -1, false, data)
end

-- by default, redirect stdout and stderr from job into buffer
M.opts = {
	on_stdout = redirect,
	on_stderr = redirect
}

-- helper function for calling docker exec using vim.fn.jobstart
local function docker_exec(container, command)
	local workdir
	-- set the workdir as cwd
	if M.use_cwd_as_workdir then
		 workdir = string.format("-w %s", vim.fn.getcwd())
	end
	-- set the workdir as M.workdir, overrides use_cwd_as_workdir
	if M.workdir ~= "" then
		workdir = string.format("-w %s", M.workdir)
	end
	-- set the host
	local host = ""
	if M.host ~= "" then
		host = string.format("-H %s", M.host)
	end
	-- construct the command for the job
	local job = string.format("docker %s exec %s %s %s", host, workdir, container, command)
	-- start the job
	vim.fn.jobstart(job, M.opts)
end

-- top-level function for executing a job
-- opens a new window in vertical split, and creates a new buffer
-- then associates the buffer with the window and prints the job output to the buffer
local function do_job(command)
	vim.cmd('vsplit')
	local win = vim.api.nvim_get_current_win()
	bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, bufnr)
	docker_exec(M.container, command)
end

-- helper function for getting the currently running docker containers on the system
-- if M.host is set, get the currently running docker containers on that host
local function get_containers()
	local command = 'docker ps --format "{{.Names}}"'
	-- set the host
	if M.host ~= "" then
		command = string.format('docker -H %s ps --format "{{.Names}}"', M.host)
	end
	local containers = {}
	local output = io.popen(command)
	for container in output:lines() do
		table.insert(containers, container)
	end
	output:close()
	return containers
end

-- top-level function for picking a container
-- creates a telescope picker window with the currently running containers
-- and sets M.container to the selected entry
local function pick_container()
	local containers = get_containers()
	local opts = themes.get_dropdown({})
	pickers.new(opts, {
		prompt_title = "Running Containers",
		finder = finders.new_table {
			results = containers
		},
		sorter = telescope_config.values.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				M.container = selection[1]
			end)
			return true
		end,
	}):find()
end


M.pick_conatiner = pick_container
M.do_job = do_job

return M
