package com.itemis.xtext.generator.vscode

import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.xtext.generator.AbstractXtextGeneratorFragment
import org.eclipse.xtext.xtext.generator.CodeConfig
import org.eclipse.xtext.xtext.generator.model.FileAccessFactory
import org.eclipse.xtext.xtext.generator.model.project.IXtextProjectConfig

import static com.itemis.xtext.generator.vscode.internal.FSAHelper.*

class VSCodeExtensionFragment extends AbstractXtextGeneratorFragment {
	@Inject FileAccessFactory fileAccessFactory
	@Inject CodeConfig codeConfig
	@Inject extension IQualifiedNameConverter
	
	@Accessors String publisher 
	@Accessors String version = "0.1"
	
	override generate() {
		generateDummyPluginProperties
		generatePackageJson
		generateConfigurationJson
		generateTmLanguage
		generateExtensionJs
		generateBuildGradle
	}
	
	
	protected def generateDummyPluginProperties () {
		val file = fileAccessFactory.createTextFile("plugin.properties")
		file.content = '''
			_UI_DiagnosticRoot_diagnostic=foo
		'''
		writeTo(file, projectConfig.genericIde.root)
	}
	
	protected def generatePackageJson () {
		val file = fileAccessFactory.createTextFile(projectConfig.vsCodeExtensionPath+"/package.json")
		file.content = '''
			{
			    "name": "«langNameLower»-sc",
			    "displayName": "«langName»",
			    "description": "«langName» Language (self-contained)",
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
			            "extensions": [".«FOR ext: language.fileExtensions SEPARATOR ","»«ext»«ENDFOR»"],
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
		writeTo(file, projectConfig.genericIde.root)
	}
	
	protected def generateConfigurationJson () {
		val file = fileAccessFactory.createTextFile(projectConfig.vsCodeExtensionPath+"/"+langNameLower+".configuration.json")
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
		writeTo(file, projectConfig.genericIde.root)
	}
	
	def protected generateTmLanguage () {
		val file = fileAccessFactory.createTextFile(projectConfig.vsCodeExtensionPath+"/syntaxes/"+langNameLower+".tmLanguage")
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
						<string>keyword.control.«langName»</string>
						<key>match</key>
						<string>\b(Hello|from)\b</string>
					</dict>
				</array>
				<key>scopeName</key>
				<string>text.«langNameLower»</string>
			</dict>
			</plist>
		'''
		writeTo(file, projectConfig.genericIde.root)
	}
	
	
	protected def generateExtensionJs () {
		val file = fileAccessFactory.createTextFile(projectConfig.vsCodeExtensionPath+"/src/extension.js")
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
		writeTo(file, projectConfig.genericIde.root)		
	}
	
	protected def generateBuildGradle () {
		val file = fileAccessFactory.createTextFile(projectConfig.vsCodeExtensionPath+"/build.gradle")
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
		writeTo(file, projectConfig.genericIde.root)		
	}
	
	def getVsCodeExtensionPath(IXtextProjectConfig config) {
		config.genericIde.root.path+"/vscode-extension"
	}

	def getLangName () {
		grammar.name.toQualifiedName.lastSegment
	}
	def getLangNameLower () {
		grammar.name.toQualifiedName.lastSegment.toLowerCase
	}
	
}