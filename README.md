# Xtext Generator Fragment for Visual Studio Code Extensions

[![Build Status](https://travis-ci.org/itemis/xtext-generator-vscode.svg?branch=master)](https://travis-ci.org/itemis/xtext-generator-vscode)

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

