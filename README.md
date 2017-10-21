<h1 align="center">
  Barebones
</h1>

<p align="center">
  :construction: Our no nonsense project template.
</p>

<p align="center">
  <a href="https://ci.appveyor.com/project/origamicomet/barebones/branch/master">
    <img alt="Build Status for Windows" src="https://img.shields.io/appveyor/ci/origamicomet/barebones.svg">
  </a>

  <a href="https://travis-ci.org/origamicomet/barebones">
    <img alt="Build Status for Mac & Linux" src="https://img.shields.io/travis/origamicomet/barebones/master.svg?label=build">
  </a>

  <a href="https://github.com/origamicomet/barebones/blob/master/LICENSE">
    <img alt="License" src="https://img.shields.io/badge/license-CC0-blue.svg">
  </a>
</p>

## Intro

This repository serves as a no nonsense template for developing cross-platform applications and libraries.

## Goals

* Standardized directory structure and tooling.

  This repository serves as the basis for the directory structure of all projects under our dominion. It also defines the interface used to build and package our software.

* No nonsense build infrastructure.

  Builds can be performed without any dependencies. If required tooling is not found, it will be fetched and cached on your behalf. An optional convenience wrapper hides the nitty-gritty and makes building a one liner. Automated builds are setup and ready to go.

* Reasonable defaults.

  Various choices have been made on your behalf to best align development with our methodologies and workflow. You can change them, but should not need to.

## Building

Build infrastructure is structured to minimize dependencies. As such, builds can be performed without installing anything beside the necessary toolchains. Any required tools, if not found, will be fetched and cached into `_build/tools/cache` automatically. You can disable automatic fetching, opting to fail if a tool cannot be found by defining `DO_NOT_FETCH_TOOLS`.

To kick off a build, you can call the underlying build scripts:

```sh
# Build for Windows using Visual Studio.
_build\build_debug_windows_32.bat
_build\build_release_windows_32.bat
_build\build_debug_windows_64.bat
_build\build_release_windows_64.bat

# Build for Mac using Clang or GCC.
_build\build_debug_mac_32.sh
_build\build_release_mac_32.sh
_build\build_debug_mac_64.sh
_build\build_release_mac_64.sh

# Build for Linux using GCC or Clang.
_build\build_debug_linux_32.sh
_build\build_release_linux_32.sh
_build\build_debug_linux_64.sh
_build\build_release_linux_64.sh
```

You can override the toolchain used by defining `TOOLCHAIN`. Otherwise a reasonable default is picked.

To reduce tedium, an optional convenience script `build.rb` is provided. It can be used to drive builds, calling the underlying build scripts on your behalf. Run `build.rb help` for details.

## Packaging

Packaging hasn't been worked out yet.

## Questions

For questions, please use our `#development` channel.

## Contributing

A [contribution guide](https://github.com/origamicomet/barebones/blob/master/CONTRIBUTING) and [code of conduct](https://github.com/origamicomet/barebones/blob/master/CODE_OF_CONDUCT) are provided.

## Changelog

A detailed [changelog](https://github.com/origamicomet/barebones/blob/master/CHANGELOG) is maintained.

## License

This template, and descendants, are given to the public domain with alternative stipulations made _just-in-case_ (CC0).
