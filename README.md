# Xtext Generator Fragment for Visual Studio Code Extensions

[![Build Status](https://travis-ci.org/itemis/xtext-generator-vscode.svg?branch=master)](https://travis-ci.org/itemis/xtext-generator-vscode)

## Usage

Add this to your project by configuring a dependency as follows:

Gradle:
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

## Workflow Configuration

```
	component = XtextGenerator {
		configuration = {
			project = com.itemis.xtext.generator.vscode.VSCodeProjectConfig {
			   ...
				vsExtension = {
					enabled = true
				}
			}
		}
		language = StandardLanguage {
			...
			fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment {}
		}
	}
```

