# Xtext Generator Fragment for Visual Studio Code

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
			fragment = com.itemis.xtext.generator.vscode.VSCodeExtensionFragment{}
		}
	}
```

