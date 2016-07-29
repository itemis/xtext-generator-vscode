package com.itemis.xtext.generator.vscode

import java.io.File
import java.io.FileWriter

class ProjectInitializer {
	String path

	def void setPath(String path) {
		this.path = path
		
		val dir = new File (path);
		if (!dir.exists) {
			dir.mkdir
			val fw = new FileWriter(new File(dir,".project"))
			fw.write(genProjectFile.toString)	
		}
		val settingsDir = new File(dir, ".settings")
		if (!settingsDir.exists) {
			settingsDir.mkdir
			val fw = new FileWriter(new File(settingsDir,"org.eclipse.buildship.core.prefs"))
			fw.write(genBuildshipPrefs.toString)	
		}
	}
	
	def genProjectFile () '''<?xml version="1.0" encoding="UTF-8"?>
		<projectDescription>
			<name>«projectName»</name>
			<comment>VS Code Extension project</comment>
			<projects>
			</projects>
			<buildSpec>
				<buildCommand>
					<name>org.eclipse.buildship.core.gradleprojectbuilder</name>
					<arguments>
					</arguments>
				</buildCommand>
			</buildSpec>
			<natures>
				<nature>org.eclipse.buildship.core.gradleprojectnature</nature>
			</natures>
		</projectDescription>
	
	'''
	
	def genBuildshipPrefs () '''
		connection.gradle.distribution=GRADLE_DISTRIBUTION(WRAPPER)
		connection.project.dir=..
		derived.resources=.gradle,build
		eclipse.preferences.version=1
		project.path=\:«projectName»
	'''
	
	def getProjectName () {
		if (path==null) throw new IllegalStateException ("Property 'path' not set")
		path.substring(path.lastIndexOf('/'))
	}
}
