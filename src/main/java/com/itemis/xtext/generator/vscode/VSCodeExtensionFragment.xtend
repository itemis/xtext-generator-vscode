package com.itemis.xtext.generator.vscode

import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.xtext.generator.AbstractXtextGeneratorFragment
import org.eclipse.xtext.xtext.generator.model.FileAccessFactory

import static com.itemis.xtext.generator.vscode.internal.FSAHelper.*

class VSCodeExtensionFragment extends AbstractXtextGeneratorFragment {

	@Inject FileAccessFactory fileAccessFactory
//	@Inject CodeConfig codeConfig
	@Accessors String publisher
	@Accessors String version = "0.0.1"

	override generate() {
		generateDummyPluginProperties
		generatePackageJson
		generateConfigurationJson
		generateTmLanguage
		generateExtensionJs
		generateBuildGradle
	}

	protected def void generateDummyPluginProperties() {
		val file = fileAccessFactory.createTextFile(projectConfig.genericIde.srcGen.path + "/plugin.properties")
		file.content = '''
			_UI_DiagnosticRoot_diagnostic=foo
		'''
		writeTo(file, projectConfig.genericIde.srcGen)
	}

	protected def void generatePackageJson() {
		val file = fileAccessFactory.createTextFile(projectConfig.vsExtension.root.path + "/package.json")
		file.content = '''
			{
			    "name": "«langNameLower»-sc",
			    "displayName": "«language.grammar.name»",
			    "description": "«language.grammar.name» Language (self-contained)",
			    "version": "«version»",
			    «IF publisher!=null»
			    	"publisher": "«publisher»",
			    «ENDIF»
			    "engines": {
			        "vscode": "^1.2.0"
			    },
			    "categories": [
			        "Languages"
			    ],
				"activationEvents": [
					"onLanguage:«langNameLower»"
				],
				"main": "src/extension",
				   "contributes": {
				       "languages": [{
				           "id": "«langNameLower»",
				           "aliases": ["«langNameLower»"],
				           "extensions": [".«FOR ext : language.fileExtensions SEPARATOR ","»«ext»«ENDFOR»"],
				           "configuration": "./«langNameLower».configuration.json"
				       }],
				       "grammars": [{
				           "language": "«langNameLower»",
				           "scopeName": "text.«langNameLower»",
				           "path": "./syntaxes/«langNameLower».tmLanguage"
				       }]
				   },
				"devDependencies": {
					"typescript": "^1.8.10",
					"vscode": "^0.11.13"
				},
				   "dependencies": {
				       "vscode-languageclient": "^2.3.0"
				   }
			}
		'''
		writeTo(file, projectConfig.vsExtension.srcGen)
	}

	protected def void generateConfigurationJson() {
		val file = fileAccessFactory.createTextFile(
			projectConfig.vsExtension.srcGen.path + "/" + langNameLower + ".configuration.json")
		file.content = '''
			{
			    "comments": {
			        // symbol used for single line comment. Remove this entry if your language does not support line comments
			        "lineComment": "//",
			        // symbols used for start and end a block comment. Remove this entry if your language does not support block comments
			        "blockComment": [ "/*", "*/" ]
			    },
			    // symbols used as brackets
			    "brackets": [
			        ["{", "}"],
			        ["[", "]"],
			        ["(", ")"]
			    ],
			    // symbols that are auto closed when typing
			    "autoClosingPairs": [
			        ["{", "}"],
			        ["[", "]"],
			        ["(", ")"],
			        ["\"", "\""],
			        ["'", "'"]
			    ],
			    // symbols that that can be used to surround a selection
			    "surroundingPairs": [
			        ["{", "}"],
			        ["[", "]"],
			        ["(", ")"],
			        ["\"", "\""],
			        ["'", "'"]
			    ]
			}
		'''
		writeTo(file, projectConfig.vsExtension.srcGen)
	}

	protected def void generateTmLanguage() {
		val file = fileAccessFactory.createTextFile(
			projectConfig.vsExtension.srcGen.path + "/syntaxes/" + langNameLower + ".tmLanguage")
		file.content = '''
			<?xml version="1.0" encoding="UTF-8"?>
			<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
			<plist version="1.0">
			<dict>
				<key>fileTypes</key>
				<array>
					<string>*.«language.fileExtensions.head»</string>
				</array>
				<key>name</key>
				<string>«langNameLower»</string>
				<key>patterns</key>
				<array>
					<dict>
						<key>name</key>
						<string>keyword.control.«language.grammar.name»</string>
						<key>match</key>
						<string>\b(Hello|from)\b</string>
					</dict>
				</array>
				<key>scopeName</key>
				<string>text.«langNameLower»</string>
			</dict>
			</plist>
		'''
		writeTo(file, projectConfig.vsExtension.srcGen)
	}

	protected def void generateExtensionJs() {
		val file = fileAccessFactory.createTextFile(projectConfig.vsExtension.srcGen.path + "/src/extension.js")
		file.content = '''
			'use strict';
			var net = require('net');
			var path = require('path');
			var vscode_lc = require('vscode-languageclient');
			var spawn = require('child_process').spawn;
			function activate(context) {
			    var serverInfo = function () {
			        // Connect to the language server via a io channel
			        var jar = context.asAbsolutePath(path.join('src', '«langNameLower»-full.jar'));
			        var child = spawn('java', ['-jar', jar]);
			        return Promise.resolve(child);
			    };
			    var clientOptions = {
			        documentSelector: ['«language.fileExtensions.head»']
			    };
			    // Create the language client and start the client.
			    var disposable = new vscode_lc.LanguageClient('Xtext Server', serverInfo, clientOptions).start();
			    // Push the disposable to the context's subscriptions so that the 
			    // client can be deactivated on extension deactivation
			    context.subscriptions.push(disposable);
			}
			exports.activate = activate;
		'''
		writeTo(file, projectConfig.vsExtension.srcGen)
	}

	protected def void generateBuildGradle() {
		val file = fileAccessFactory.createTextFile(projectConfig.vsExtension.srcGen.path + "/build.gradle")
		file.content = '''
			/**
			 * Problem: right now we cannot install the plugin in a headless mode.
			 * That's why we need this hacky task...
			 * @see https://github.com/Microsoft/vscode/issues/9585
			 */
			task installExtension(type: Exec, dependsOn: vscodeExtension) {
			    commandLine 'code'
			    args vscodeExtension.destPath, '--new-window'
			    doLast {
			        Thread.sleep(5000)
			    }
			}
			
			task startCode(type:Exec, dependsOn: installExtension) {
			    commandLine 'code'
			    args "$rootProject.projectDir/demo/", '--reuse-window'
			}
		'''
		writeTo(file, projectConfig.vsExtension.srcGen)
	}

	override IVSCodeProjectConfig getProjectConfig() {
		super.getProjectConfig() as IVSCodeProjectConfig
	}

	def String getLangNameLower() {
		grammar.name.toLowerCase
	}

}
