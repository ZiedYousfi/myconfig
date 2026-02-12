vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

if vim.fn.has("win32") == 1 then
	local py = vim.fn.exepath("py")
	if py == "" then
		py = vim.fn.exepath("python")
	end
	if py ~= "" then
		local dir = vim.fn.fnamemodify(py, ":h")
		local real_python = vim.fn.system('py -c "import sys; print(sys.executable)"'):gsub("%s+$", "")
		if real_python ~= "" then
			local real_dir = vim.fn.fnamemodify(real_python, ":h")
			vim.env.PATH = real_dir .. ";" .. vim.env.PATH
		end
	end
end

require("config.lazy")
