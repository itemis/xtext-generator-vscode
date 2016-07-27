/*******************************************************************************
 * Copyright (c) 2016 itemis AG (http://www.itemis.de) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package com.itemis.xtext.generator.vscode

import java.util.Collections
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
import static extension org.eclipse.xtext.xtext.generator.util.GrammarUtil2.*
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

	/** 
	 * If set, add Java remote debugging options to the JVM. 
	 * When 'javaOptions' are set, the debug options are set before the other options.
	 */
	Integer debugPort
	def void setDebugPort (String debugPort) {
		this.debugPort = Integer.valueOf(debugPort)
	}
	
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
		generateExtensionJs (langId, language.fileExtensions)
		generateBuildGradle_VSCExtension
		generateBuildGradle_GenericIDE
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
		val inheritsTerminals = grammar.inherits(TERMINALS)
		file.content = '''
			{
			    "comments": {
			    		«IF inheritsTerminals»
				        // symbol used for single line comment. Remove this entry if your language does not support line comments
				        "lineComment": "//",
				        // symbols used for start and end a block comment. Remove this entry if your language does not support block comments
				        "blockComment": [ "/*", "*/" ]
			        «ENDIF»
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
	
	
	protected def generateExtensionJs (String langId, String[] langFileExt) {
		val file = fileAccessFactory.createTextFile(projectConfig.vsCodeExtensionPath+"/src/extension.js")
		val jvmOptions = getJVMOptions()
		file.content = '''
			'use strict';
			var net = require('net');
			var path = require('path');
			var vscode_lc = require('vscode-languageclient');
			var spawn = require('child_process').spawn;
			function activate(context) {
			    var serverInfo = function () {
			        // Connect to the language server via a io channel
			        var jar = context.asAbsolutePath(path.join('src', '«langId»-full.jar'));
			        var child = spawn('java', [«IF jvmOptions!=null»'«jvmOptions»',«ENDIF»'-jar', jar]);
			        child.stdout.on('data', function (chunk) {
			            console.log(chunk.toString());
			        });
			        child.stderr.on('data', function (chunk) {
			            console.error(chunk.toString());
			        });
			        return Promise.resolve(child);
			    };
			    var clientOptions = {
			        documentSelector: ['«langFileExt.join(",")»']
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
	
	/**
	 * Compute the JVM options line.
	 */
	def private String getJVMOptions () {
		val b = new StringBuilder
		if (debugPort != null) {
			b.append("-Xdebug -Xrunjdwp:server=y,transport=dt_socket,address="+debugPort+",suspend=n")
		}
		if (javaOptions != null) {
			if (debugPort != null) b.append(" ")
			b.append(javaOptions)
		}
		
		return if (b.toString.empty) null else b.toString
	}
	
	protected def generateBuildGradle_VSCExtension () {
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
			
			task publish(dependsOn: vscodeExtension, type: NodeTask) {
			    script = file("$rootProject.projectDir/node_modules/vsce/out/vsce")
			    args = [ 'publish', '-p', System.getenv('ACCESS_TOKEN'), project.version ]
			    execOverrides {
			        workingDir = projectDir
			    }
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

	protected def generateBuildGradle_GenericIDE () {
		val file = fileAccessFactory.createTextFile(projectConfig.genericIde.root.path+"/build.gradle")
		file.content = '''
			plugins {
				id 'com.github.johnrengelman.shadow' version '1.2.3'
			}
			
			apply plugin: 'application'
			
			import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar
			
			dependencies {
				compile project(':org.xtext.example.mydsl')
				compile "org.eclipse.xtext:org.eclipse.xtext.ide:${xtextVersion}"
				compile "org.eclipse.xtext:org.eclipse.xtext.xbase.ide:${xtextVersion}"
			}
			
			mainClassName = "org.xtext.example.mydsl.ide.RunServer"
			
			startScripts {
				applicationName = 'MyDsl Language Server'
			}
			
			task socketShadowJar(type: ShadowJar, dependsOn: assemble) {
				manifest.attributes 'Main-Class': 'org.xtext.example.mydsl.ide.RunServer'
				from(project.convention.getPlugin(JavaPluginConvention).sourceSets.main.output)
				configurations = [project.configurations.runtime]
				exclude('META-INF/INDEX.LIST', 'META-INF/*.SF', 'META-INF/*.DSA', 'META-INF/*.RSA')
				classifier = 'socket-all'
			}
			
			task ioShadowJar(type: ShadowJar, dependsOn: assemble) {
				manifest.attributes 'Main-Class': 'org.eclipse.xtext.ide.server.ServerLauncher'
				from(project.convention.getPlugin(JavaPluginConvention).sourceSets.main.output)
				configurations = [project.configurations.runtime]
				exclude('META-INF/INDEX.LIST', 'META-INF/*.SF', 'META-INF/*.DSA', 'META-INF/*.RSA')
				baseName = 'mydsl-full'
				classifier = null
				version = null
				destinationDir = file("$projectDir/../vscode-extension-self-contained/src")
			}
			
			task shadowJars {
				dependsOn socketShadowJar, ioShadowJar
			}
			
			clean.doFirst {
			    delete tasks.ioShadowJar.archivePath
			}
		'''	
		writeTo(file, projectConfig.genericIde.root)
	}
}