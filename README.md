# Pharo Language Server

[![Continuous](https://github.com/badetitou/Pharo-LanguageServer/actions/workflows/continuous.yml/badge.svg)](https://github.com/badetitou/Pharo-LanguageServer/actions/workflows/continuous.yml)
[![Pharo 10](https://img.shields.io/badge/Pharo-11-%23aac9ff.svg)](https://github.com/pharo-project/pharo)
[![Moose version](https://img.shields.io/badge/Moose-11-%23aac9ff.svg)](https://github.com/moosetechnology/Moose)
[![Coverage Status](https://coveralls.io/repos/github/badetitou/Pharo-LanguageServer/badge.svg?branch=v4)](https://coveralls.io/github/badetitou/Pharo-LanguageServer?branch=v4)

I am an implementation of the [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/implementors/servers/) for the [Pharo programming language](https://pharo.org/).
My main goal is to provide a unique interface for several generic IDE to manipulate a Pharo environment.

I am used by the following client extensions:

- [vscode-pharo](https://github.com/badetitou/vscode-pharo)

## Features

As a language server, I accept two Pharo/SmallTalk formats:

- *.st* for smalltalk script (as you can see in a playground).
- *.class.st* for tonel files.

Most of the features are available for both formats.

- Code highlighting
- Hover
- Auto-completion

### Script specific features

- Code formatting

### Tonel specific features

- Saving the file create/update the corresponding class in the image

## Installation


Execute this code in any Pharo10/11 Image

```Smalltalk
Metacello new
  githubUser: 'badetitou' project: 'Pharo-LanguageServer' commitish: 'v4' path: 'src';
  baseline: 'PharoLanguageServer';
  load
```
