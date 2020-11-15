# Pharo Language Server

I am an implementation of the [Language Server Protocol (LSP)](https://microsoft.github.io/language-server-protocol/implementors/servers/) for the [Pharo programming language](https://pharo.org/).
My main goal is to provide a unique interface for several generic IDE to manipulate a Pharo environment.

I am used by the following client extensions:

- [vscode-pharo](https://github.com/badetitou/vscode-pharo)

## Features

As a language server, I accept two pharo/smalltalk formats:

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
