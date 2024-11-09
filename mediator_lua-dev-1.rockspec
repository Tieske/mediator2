local package_name = "mediator_lua"
local package_version = "dev"
local rockspec_revision = "1"
local github_account_name = "Olivine-labs"
local github_repo_name = package_name

package = package_name
version = package_version.."-"..rockspec_revision
source = {
  url = "git+https://github.com/"..github_account_name.."/"..github_repo_name..".git",
  branch = (package_version == "dev") and "main" or nil,
  tag = (package_version ~= "dev") and ("v" .. package_version) or nil,
}

description = {
  summary = "Event handling through channels",
  detailed = [[
    mediator_lua allows you to subscribe and publish to a central object so
    you can decouple function calls in your application. It's as simple as
    mediator:subscribe({"channel"}, function). Supports namespacing, predicates,
    and more.
  ]],
  homepage = "https://olivinelabs.com/mediator_lua/",
  license = "MIT <http://opensource.org/licenses/MIT>"
}

dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    mediator = "src/mediator.lua"
  }
}
