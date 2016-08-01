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
import org.eclipse.emf.mwe2.runtime.Mandatory

class VSCodeExtensionFragment extends AbstractXtextGeneratorFragment {
	@Inject FileAccessFactory fileAccessFactory
	@Inject CodeConfig codeConfig
	@Inject extension IQualifiedNameConverter
	
	@Accessors(PUBLIC_SETTER)
	static class Versions {
		/** Version of the resulting extension */
		String vscExtension = "0.1.0"
		/** VSCode Engine version. Default: ^1.2.0*/
		String vscEngine = "^1.2.0"
		String typescript = "^1.8.10"
		String vscode = "^0.11.13"
		String vscodeLanguageclient = "^2.3.0"
		String shadowJarGradlePlugin = "1.2.3"
		String xtext = "2.11.0-SNAPSHOT"
	}
	
	/** If set, the build will add snapshot repositories for Xtext, ls-api */	
	@Accessors(PUBLIC_SETTER)
	Boolean useSnapshotRepositories = false

	/** Publisher name */
	String publisher
	@Mandatory
	def void setPublisher (String publisher) {
		this.publisher = publisher
	}

	/** Extension License */	
	@Accessors(PUBLIC_SETTER)
	String license
	
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
		generateGradleProperties
		generateBuildGradle_VSCExtension (langId)
	}
	
	
	protected def generateDummyPluginProperties () {
		val file = fileAccessFactory.createTextFile("plugin.properties")
		file.content = '''
			_UI_DiagnosticRoot_diagnostic=foo
		'''
		writeTo(file, projectConfig.genericIde.srcGen)
	}
	
	protected def generatePackageJson (String langId, String[] langFileExt) {
		val file = fileAccessFactory.createTextFile(vscodeExtensionPath+"/package.json")
		file.content = '''
			{
			    "name": "«langId»",
			    "displayName": "«langName»",
			    "description": "«langName» Language",
			    "version": "«versions.vscExtension»",
			    "publisher": "«publisher»",
			    «IF license!=null»
			    		"license": "«license»",
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
	
	def getVscodeExtensionPath() {
		"vscode"
	}
	
	protected def generateConfigurationJson () {
		val file = fileAccessFactory.createTextFile(vscodeExtensionPath+"/"+langNameLower+".configuration.json")
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
		val file = fileAccessFactory.createTextFile(vscodeExtensionPath+"/syntaxes/"+langId+".tmLanguage")
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
		val file = fileAccessFactory.createTextFile(vscodeExtensionPath+"/src/extension.js")
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
			        var jar = context.asAbsolutePath(path.join('src', '«langId»-uber.jar'));
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
	
	protected def generateGradleProperties () {
		val file = fileAccessFactory.createTextFile(vscodeExtensionPath+"/gradle.properties")
		file.content = '''
			version = «versions.vscExtension»
		'''
		writeTo(file, projectConfig.genericIde.root)
	}
	
	protected def generateBuildGradle_VSCExtension (String langId) {
		val file = fileAccessFactory.createTextFile(vscodeExtensionPath+"/build.gradle")
		file.content = '''
			buildscript {
				repositories {
					jcenter()
				}
				dependencies {
					classpath 'org.xtext:xtext-gradle-plugin:1.0.5'
					classpath 'com.moowork.gradle:gradle-node-plugin:0.13'
				}
			}
			
			plugins {
				id 'com.github.johnrengelman.shadow' version '«versions.shadowJarGradlePlugin»'
				id 'com.moowork.node' version '0.13'
				id 'net.researchgate.release' version '2.4.0'
			}
			
			node {
				version = '6.2.2'
				npmVersion = '3.10.6'
				download = true
			}
			
			apply plugin: 'java'
			apply plugin: 'com.moowork.node'
			
			ext.xtextVersion = '«versions.xtext»'
			
			repositories {
				jcenter()
				mavenLocal()
				«IF useSnapshotRepositories»
					maven { url 'http://services.typefox.io/open-source/jenkins/job/lsapi/lastStableBuild/artifact/build/maven-repository/' }
					maven { url 'http://services.typefox.io/open-source/jenkins/job/xtext-lib/job/master/lastStableBuild/artifact/build/maven-repository/' }
					maven { url 'http://services.typefox.io/open-source/jenkins/job/xtext-core/job/master/lastStableBuild/artifact/build/maven-repository/' }
					maven { url 'http://services.typefox.io/open-source/jenkins/job/xtext-extras/job/master/lastStableBuild/artifact/build/maven-repository/' }
					maven { url 'http://services.typefox.io/open-source/jenkins/job/xtext-xtend/job/master/lastStableBuild/artifact/build/maven-repository/' }
					maven {
						url 'https://oss.sonatype.org/content/repositories/snapshots'
					}
				«ENDIF»
			}
			
			dependencies {
				compile "«projectConfig.runtime.name»:«projectConfig.runtime.name»:+"
				compile "«projectConfig.runtime.name»:«projectConfig.genericIde.name»:+"
				compile "org.eclipse.xtext:org.eclipse.xtext.ide:${xtextVersion}"
				compile "org.eclipse.xtext:org.eclipse.xtext.xbase.ide:${xtextVersion}"
			}
			
			task ioShadowJar(type: com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar, dependsOn: assemble) {
				manifest.attributes 'Main-Class': 'org.eclipse.xtext.ide.server.ServerLauncher'
				from(project.convention.getPlugin(JavaPluginConvention).sourceSets.main.output)
				configurations = [project.configurations.runtime]
				exclude('META-INF/INDEX.LIST', 'META-INF/*.SF', 'META-INF/*.DSA', 'META-INF/*.RSA')
				baseName = '«langId»-uber'
				classifier = null
				version = null
				destinationDir = file("$projectDir/src")
			}
			
			task shadowJars {
				dependsOn ioShadowJar
			}
			
			clean.doFirst {
			    delete tasks.ioShadowJar.archivePath
			}
			
			task npmInstallVsce(type: NpmTask, dependsOn: npmSetup) {
				group 'Node'
				description 'Installs the NodeJS package "Visual Studio Code Extension Manager"'
				args = [ 'install', 'vsce' ]
			}
			
			npmInstall.dependsOn 'shadowJars'
			
			task vscodeExtension(dependsOn: [npmInstall, npmInstallVsce], type: NodeTask) {
				ext.destDir = buildDir
				ext.archiveName = "«langId»-${project.version}.vsix"
				ext.destPath = "$destDir/$archiveName"
				outputs.dir destDir
				doFirst {
					destDir.mkdirs()
				}
				script = file("$projectDir/node_modules/vsce/out/vsce")
				args = [ 'package', '--out', destPath ]
				execOverrides {
					workingDir = projectDir
				}
			}
			
			plugins.withType(com.moowork.gradle.node.NodePlugin) {
				node {
					workDir = file("$project.buildDir/nodejs")
					nodeModulesDir = projectDir
				}
			}
			
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
			    // args "$rootProject.projectDir/demo/", '--reuse-window'
			}
			
			task publish(dependsOn: vscodeExtension, type: NodeTask) {
			    script = file("$projectDir/node_modules/vsce/out/vsce")
			    args = [ 'publish', '-p', System.getenv('ACCESS_TOKEN'), project.version ]
			    execOverrides {
			        workingDir = projectDir
			    }
			}
			
			task updateVersions << {
			    def versionPattern = /\d+.\d+(.\d+)?/
			    def encoding = 'UTF-8'
			    def filesToUpdate = [
					new File('package.json'),
				]
			
			    // String replacements - isn't long enough to justify advanced code ;)
				filesToUpdate.forEach { file ->
					String text = file.getText(encoding)
					text = text.replaceAll("\"version\": \"$versionPattern\",", "\"version\": \"$project.version\",")
					file.setText(text, encoding)
				}
			}
			
			updateVersions.shouldRunAfter tasks.getByName('confirmReleaseVersion')
			
			/*
			 * Configure release plugin.
			 * Remove tasks "updateVersion" and "commitNewVersion" as we don't need to increment the
			 * version to a SNAPSHOT before the next release.
			 */
			tasks.release.tasks -= ["updateVersion", "commitNewVersion"]
			release {
			    preTagCommitMessage = '[release] '
			    tagCommitMessage = '[release] '
			    tagTemplate = 'v${version}'
			}
			tasks.getByName('preTagCommit').dependsOn updateVersions
		'''
		writeTo(file, projectConfig.genericIde.root)		
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