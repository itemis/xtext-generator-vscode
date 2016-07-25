package com.itemis.xtext.generator.vscode

import java.util.Collections
import java.util.List
import java.util.regex.Pattern
import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.xtext.generator.AbstractXtextGeneratorFragment
import org.eclipse.xtext.xtext.generator.CodeConfig
import org.eclipse.xtext.xtext.generator.model.FileAccessFactory
import org.eclipse.xtext.xtext.generator.model.project.IXtextProjectConfig

import static com.itemis.xtext.generator.vscode.internal.FSAHelper.*

import static extension org.eclipse.xtext.GrammarUtil.*
import static extension org.eclipse.xtext.xtext.generator.web.RegexpExtensions.*

class VSCodeExtensionFragment extends AbstractXtextGeneratorFragment {
	@Inject FileAccessFactory fileAccessFactory
	@Inject CodeConfig codeConfig
	@Inject extension IQualifiedNameConverter
	
	@Accessors(PUBLIC_SETTER)
	static class Versions {
		String vscExtension = "0.1"
		/** VSCode Engine version. Default: ^1.2.0*/
		String vscEngine = "^1.2.0"
		String typescript = "^1.8.10"
		String vscode = "^0.11.13"
		String vscodeLanguageclient = "^2.3.0"
	}
	
	/** Publisher name */
	@Accessors(PUBLIC_SETTER)
	String publisher 
	
	@Accessors(PUBLIC_SETTER)
	Versions versions = new Versions
	
	/** Additional options for the JVM */
	@Accessors(PUBLIC_SETTER)
	String javaOptions
	
	/** Name of the Language Server. Default: "Xtext Server"*/
	@Accessors(PUBLIC_SETTER)
	String languageServerName = "Xtext Server"

	/**
	 * Regular expression for filtering those language keywords that should be highlighted. The default
	 * is {@code \w+}, i.e. keywords consisting only of letters and digits.
	 */
	@Accessors(PUBLIC_SETTER)
	String keywordsFilter = "\\w+"
	 

	override generate() {
		val langId = langNameLower
		generateDummyPluginProperties
		generatePackageJson (langId, language.fileExtensions)
		generateConfigurationJson
		generateTmLanguage (langId, language.fileExtensions)
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
	
	protected def generatePackageJson (String langId, String[] langFileExt) {
		val file = fileAccessFactory.createTextFile(projectConfig.vsCodeExtensionPath+"/package.json")
		file.content = '''
			{
			    "name": "«langId»-sc",
			    "displayName": "«langName»",
			    "description": "«langName» Language (self-contained)",
			    "version": "«versions.vscExtension»",
			    «IF publisher!=null»
			    "publisher": "«publisher»",
			    «ENDIF»
			    "engines": {
			        "vscode": "«versions.vscEngine»"
			    },
			    "categories": [
			        "Languages"
			    ],
				"activationEvents": [
					"onLanguage:«langId»"
				],
				"main": "src/extension",
			    "contributes": {
			        "languages": [{
			            "id": "«langId»",
			            "aliases": ["«langId»"],
			            "extensions": [".«FOR ext: langFileExt SEPARATOR ","»«ext»«ENDFOR»"],
			            "configuration": "./«langId».configuration.json"
			        }],
			        "grammars": [{
			            "language": "«langId»",
			            "scopeName": "text.«langId»",
			            "path": "./syntaxes/«langId».tmLanguage"
			        }]
			    },
				"devDependencies": {
					"typescript": "«versions.typescript»",
					"vscode": "«versions.vscode»"
				},
			    "dependencies": {
			        "vscode-languageclient": "«versions.vscodeLanguageclient»"
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
	
	def protected generateTmLanguage (String langId, String[] langFileExt) {
		val file = fileAccessFactory.createTextFile(projectConfig.vsCodeExtensionPath+"/syntaxes/"+langId+".tmLanguage")
		file.content = '''
			<?xml version="1.0" encoding="UTF-8"?>
			<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
			<plist version="1.0">
			<dict>
				<key>fileTypes</key>
				<array>
					<string>«FOR ext: langFileExt SEPARATOR ","»*.«ext»«ENDFOR»</string>
				</array>
				<key>name</key>
				<string>«langId»</string>
				<key>patterns</key>
				<array>
					<dict>
						<key>name</key>
						<string>keyword.control.«langId»</string>
						<key>match</key>
						<string>\b(«keywordPattern»)\b</string>
					</dict>
				</array>
				<key>scopeName</key>
				<string>text.«langId»</string>
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
			        var child = spawn('java', [«IF javaOptions!=null»'«javaOptions»,«ENDIF»'-jar', jar]);
			        return Promise.resolve(child);
			    };
			    var clientOptions = {
			        documentSelector: ['«language.fileExtensions.head»']
			    };
			    // Create the language client and start the client.
			    var disposable = new vscode_lc.LanguageClient('«languageServerName»', serverInfo, clientOptions).start();
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

	@Pure
	def getLangName () {
		grammar.name.toQualifiedName.lastSegment
	}

	@Pure
	def getLangNameLower () {
		grammar.name.toQualifiedName.lastSegment.toLowerCase
	}

	def protected String getKeywordPattern() {
		val allKeywords = grammar.allKeywords
		val wordKeywords = newArrayList
		val nonWordKeywords = newArrayList
		val keywordsFilterPattern = Pattern.compile(keywordsFilter)
		val wordKeywordPattern = Pattern.compile('\\w(.*\\w)?')
		allKeywords.filter[keywordsFilterPattern.matcher(it).matches].forEach[
			if (wordKeywordPattern.matcher(it).matches)
				wordKeywords += it
			else
				nonWordKeywords += it
		]
		Collections.sort(wordKeywords)
		Collections.sort(nonWordKeywords)

		val result = (wordKeywords+nonWordKeywords).map[it.toRegexpString(false)].join('|')
		result
	}
	
}