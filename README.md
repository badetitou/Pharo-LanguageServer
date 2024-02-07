# Pharo Language Server

[![Continuous](https://github.com/badetitou/Pharo-LanguageServer/actions/workflows/continuous.yml/badge.svg)](https://github.com/badetitou/Pharo-LanguageServer/actions/workflows/continuous.yml)
[![Pharo 10](https://img.shields.io/badge/Pharo-11-%23aac9ff.svg)](https://github.com/pharo-project/pharo)
[![Moose version](https://img.shields.io/badge/Moose-11-%23aac9ff.svg)](https://github.com/moosetechnology/Moose)
[![Coverage Status](https://coveralls.io/repos/github/badetitou/Pharo-LanguageServer/badge.svg?branch=v4)](https://coveralls.io/github/badetitou/Pharo-LanguageServer?branch=v4)

I am an implementation of the [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/implementors/servers/) for the [Pharo programming language](https://pharo.org/).
My main goal is to provide a unique interface for several generic IDE to manipulate a Pharo environment.

I am used by the following client extensions:

- [vscode-pharo](https://github.com/badetitou/vscode-pharo)
- [vscode-eclipse](https://github.com/badetitou/eclipse-pharo) *Really only a POC. But you might be interested to have a look at it.*

> If you experiement with other IDE, do not hesitate to contact us in an Issue :)

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

> Or download a pre-existing image in the [release](https://github.com/badetitou/Pharo-LanguageServer/releases) section.

## Usage

Once you have an image with the project installed, you can run it using

```sh
/path/to/vm/pharo [--headless] /path/to/pls.image st /path/to/run-server.st
```

In above example, we used an another file named `run-server.st` that is used to define the Pharo script that run the code.
You can find the definition of this file for the [vscode extension](https://github.com/badetitou/vscode-pharo/blob/main/res/run-server.st) and for the [eclipse extension](https://github.com/badetitou/eclipse-pharo/blob/main/res/run-server.st).

Basically the file looks like this

```st
| server |
"Stop and reset potential existing instance in the image you start"
PLSServer reset.
"Create a new Language Server"
server := PLSServer new.
"Start the new language server"
server start.
```

By default, the server will start a socket and give you the port of the opened socket in the standard output.
If you want to use standard input/ouput to deal with communication, you can use the folowing option:

```st
server := PLSServer new
  withStdIO: true;
  yourself
```

> This option is less tested and might create bug with Pharo writing to the standard output for other reason
