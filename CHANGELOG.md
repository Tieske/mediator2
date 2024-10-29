# CHANGELOG

## Versioning

This library is versioned based on Semantic Versioning ([SemVer](https://semver.org/)).

#### Version scoping

The scope of what is covered by the version number excludes:

- error messages; the text of the messages can change, unless specifically documented.

#### Releasing new versions

- create a release branch
- update the changelog below
- update version and copyright-years in `./LICENSE.md` and `./src/mediator.lua` (in doc-comments
  header, and in module constants)
- create a new rockspec and update the version inside the new rockspec:<br/>
  `cp mediator_lua-dev-1.rockspec ./rockspecs/mediator_lua-X.Y.Z-1.rockspec`
- test: run `busted` and `luacheck .`
- render the docs: run `ldoc .`
- commit the changes as `release X.Y.Z`
- push the commit, and create a release PR
- after merging tag the release commit with `vX.Y.Z`
- upload to LuaRocks:<br/>
  `luarocks upload ./rockspecs/mediator_lua-X.Y.Z-1.rockspec --api-key=ABCDEFGH`
- test the newly created rock:<br/>
  `luarocks install mediator_lua`

## Version history

### Version X.Y.Z, unreleased

- a fix
- a change

### Version 0.1.0, released 01-Jan-2022

- initial release
