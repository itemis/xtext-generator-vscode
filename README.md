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
		mwe2 'com.itemis.xtext:generator-vscode:0.1'
	}
```

**Workflow Configuration**

Add the `VSCodeExtensionFragment` to the Xtext Generator workflow component.

```
	component = XtextGenerator {
		language = StandardLanguage {
			...
			fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment {}
		}
	}
```

**Execute Xtext Generator**

Run the Xtext generator workflow. It will create a folder `vscode-extension` within the `.ide` project.
