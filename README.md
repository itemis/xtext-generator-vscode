# Xtext Generator Fragment for Visual Studio Code Extensions

[![Build Status](https://travis-ci.org/itemis/xtext-generator-vscode.svg?branch=master)](https://travis-ci.org/itemis/xtext-generator-vscode)

## Usage

**Gradle**

Add this to your project by configuring a dependency as follows: 

```
repositories {
  maven {
    url  "http://dl.bintray.com/itemis/maven" 
  }
}

dependencies {
  mwe2 'com.itemis.xtext:generator-vscode:0.2'
}
```

**Workflow Configuration**

Add the `VSCodeExtensionFragment` to the Xtext Generator workflow component.

```
component = XtextGenerator {
  language = StandardLanguage {
    ...
    fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment {
      // fragment configuration goes here...
    }
  }
}
```

**Execute Xtext Generator**

Run ```gradle install```. Additionally to the language implementation a folder `vscode` will be produced within the `.ide` project. The folder contains a subproject for the VS Code extension.

To build the extension, go into the `vscode` folder and enter ```gradle startCode```.

The resulting extension is built to ```vscode/build/<dsl>-<version>.vsix``` and installed into VS Code.

