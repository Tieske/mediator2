# CHANGELOG

## Versioning

This library is versioned based on Semantic Versioning ([SemVer](https://semver.org/)).

#### Version scoping

The scope of what is covered by the version number excludes:

- error messages; the text of the messages can change, unless specifically documented.

#### Releasing new versions

- create a release branch
- update the changelog below
- update version and copyright-years in `./LICENSE.md` and `./src/mediator2/init.lua` (in doc-comments
  header, and in module constants)
- create a new rockspec and update the version inside the new rockspec:<br/>
  `cp mediator2-dev-1.rockspec ./rockspecs/mediator2-X.Y.Z-1.rockspec`
- test: run `busted` and `luacheck .`
- render the docs: run `ldoc .`
- commit the changes as `release X.Y.Z`
- push the commit, and create a release PR
- after merging tag the release commit with `vX.Y.Z`
- upload to LuaRocks:<br/>
  `luarocks upload ./rockspecs/mediator2-X.Y.Z-1.rockspec --api-key=ABCDEFGH`
- test the newly created rock:<br/>
  `luarocks install mediator2`

## Version history

### Version 2.0.0, unreleased

- Forked from the [Olivine-Labs original](https://github.com/Olivine-Labs/mediator_lua)
- fix: ci moved to Github Actions
- fix: linter errors
- fix: priority cannot be 0, since Lua arrays start at 1
- fix: set channel property on subscriber, drop 'stopped' as it was unused
- fix: use proper 'self' instead of upvalue in channel
- feat: add `ldoc` based documentation
- feat: allow Subscriber to update its priority
- BREAKING: remove the exported Channel and Subscriber functions.
