# How to Contribute to Jasonelle iOS

Please create an issue in [Jasonelle/Jasonelle](https://github.com/jasonelle/jasonelle) before making a pull request in order to talk about
how to approach a solution.

## Maintainers

- [@CLSource](https://github.com/clsource): (current | main) 2018 - present.

- [@gliechtenstein](https://github.com/gliechtenstein): (retired | creator) 2016 - 2018.

## Branches

This repo contains the following branches.

### `master`

Stores code that can be used. Is updated once in a while with the
code in `develop`.

### `develop`

This branch contains **bleeding edge** code. May break the build.
Is merged to master when enough changes (not more than two weeks of work) are made and compiles successfully.

- Only code in the `develop` branch can be merged into master.

- All commits must be merged. No rebasing or squashing.

- Other branches must be deleted or archived when it's purpose is met.

- `uncrustify` (code style standarization) should be applied before merging into `master`.

## Releases

*Jasonelle* will release a new version every six months (June 9 and November 6) in the repository [Jasonelle/Jasonelle](https://github.com/jasonelle/jasonelle).

- A release will contain the master branch of each project (Android, iOS, tools). The code in master must be tagged with the release version.

- The version number would be discussed with all the team leaders before hand. 