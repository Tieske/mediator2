local package_name = "mediator2"
local package_version = "dev"
local rockspec_revision = "1"
local github_account_name = "Tieske"
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
    mediator2 allows you to subscribe and publish to a central object so
    you can decouple function calls in your application. It's as simple as
    mediator:addSubscriber({"channel"}, function). Supports namespacing, predicates,
    and more.
  ]],
  homepage = "https://github.com/"..github_account_name.."/"..github_repo_name,
  license = "MIT <http://opensource.org/licenses/MIT>"
}

dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    ["mediator2.init"] = "src/mediator2/init.lua"
  }
}
