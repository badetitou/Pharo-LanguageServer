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

## Installation

There is two ways to download this project: 

- by downloading a pre-build image (in [releases](https://github.com/badetitou/Pharo-LanguageServer/releases) or from the pharo launcher)
- by loading the code in a Pharo Image

### Add project in PharoLauncher

To add this project into the pharo launcher:

1. Download the [PharoLauncher](https://pharo.org/download)
2. Open PharoLauncher
3. Open a playground
4. Execute the following piece of code

```Smalltalk
| sources |
sources := {
    PhLTemplateSource new
        type: #HttpListing;
        name: 'Pharo Language Server';
        url: 'https://github.com/badetitou/Pharo-LanguageServer/releases';
        filterPattern: 'href="([^"]*/Pharo[0-9][^"]*.zip)"';
        templateNameFormat: '{6} ({5})' }.
    PhLUserTemplateSources sourcesFile writeStreamDo: [ :s | 
        (STON writer on: s)
            newLine: String lf;
            prettyPrint: true;
            nextPut: sources ]
```

### Load the code 

Execute this code in any Pharo Image

```Smalltalk
Metacello new
  githubUser: 'badetitou' project: 'Pharo-LanguageServer' path: 'src';
  baseline: 'PharoLanguageServer';
  load
```
