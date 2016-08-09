# Xtext Generator Fragment for Visual Studio Code Extensions

[![Build Status](https://travis-ci.org/itemis/xtext-generator-vscode.svg?branch=master)](https://travis-ci.org/itemis/xtext-generator-vscode)

## Usage

###Gradle

Add this to your project by configuring a dependency as follows: 

```
repositories {
  maven {
    url  "http://dl.bintray.com/itemis/maven" 
  }
}

dependencies {
  mwe2 'com.itemis.xtext:generator-vscode:0.3'
}
```

###Workflow Configuration

Add the `VSCodeExtensionFragment` to the Xtext Generator workflow component.

```
component = XtextGenerator {
  language = StandardLanguage {
    ...
    fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment {
      provider = "My Company" // this property is mandatory
      // fragment configuration goes here...
    }
  }
}
```

###Build & Install

Run ```gradle install```. Additionally to the language implementation a folder `vscode` will be produced within the `.ide` project. The folder contains a subproject for the VS Code extension.

To build the extension, go into the `vscode` folder and enter ```gradle startCode```.

The resulting extension is built to ```vscode/build/<dsl>-<version>.vsix``` and installed into VS Code.

##Fragment Configuration

**provider**

Extension provider name. This is a mandatory property for VS Code extensions. Since there is no reasonable default, this property is also mandatory for the fragment configuration.

Example:

```
fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment {
  provider = "My Company" // this property is mandatory
}
```


**license**

Extension License name.

Example:

```
fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment {
  license = "EPL-1.0"
}
```

**debugPort**

Specify a port for remote debugging the Xtext server process. This will add Java remote debugging options to the spawned JVM.

Example:

```
fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment {
  debugPort = "8000"
}
```

**javaOptions**

Specify additional options for the JVM.


Example:

```
fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment {
  javaOption = "-Xms64M -Xmx256M"
}
```

**versions**

Allows to override the versions used for dependencies and build plugins. This is a composite property which has the following contained properties:

<table>
<tr><th>Property</th><th>Description</th><th>Default</th></tr>
<tr>
  <td>vscExtension</td>
  <td>Version of the resulting extension</td>
  <td>0.1.0</td>
</tr>
<tr>
  <td>xtext</td>
  <td>Xtext version</td>
  <td>2.11.0-SNAPSHOT</td>
</tr>
<tr>
  <td>vscEngine</td>
  <td>VSCode Engine version</td>
  <td>^1.2.0</td>
</tr>
<tr>
  <td>typescript</td>
  <td>TypeScript version</td>
  <td>^1.8.10</td>
</tr>
<tr>
  <td>vscode</td>
  <td>VS Code version</td>
  <td>^0.11.13</td>
</tr>
<tr>
  <td>vscodeLanguageclient</td>
  <td>VS Code Language Client version</td>
  <td>^2.3.0</td>
</tr>
<tr>
  <td>node</td>
  <td>Node version</td>
  <td>6.2.2</td>
</tr>
<tr>
  <td>npm</td>
  <td>NPM version</td>
  <td>3.10.6</td>
</tr>
<tr>
  <td>nodeGradlePlugin</td>
  <td>Version for Gradle plugin com.moowork.node</td>
  <td>0.13</td>
</tr>
<tr>
  <td>shadowJarGradlePlugin</td>
  <td>Version for Gradle plugin com.github.johnrengelman.shadow</td>
  <td>1.2.3</td>
</tr>
</table>

Example:

```
fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment {
  versions = {
  	vscExtension = "1.0.0"
  	node = "6.2.0"
  }
}
```
