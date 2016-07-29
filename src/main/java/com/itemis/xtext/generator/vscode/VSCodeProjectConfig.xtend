package com.itemis.xtext.generator.vscode

import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.xtext.generator.model.project.StandardProjectConfig
import org.eclipse.xtext.xtext.generator.model.project.SubProjectConfig

@Accessors
class VSCodeProjectConfig extends StandardProjectConfig implements IVSCodeProjectConfig {
	SubProjectConfig vsExtension = new SubProjectConfig

	override List<? extends SubProjectConfig> getAllProjects() {
		val projects = newArrayList
		projects+=super.allProjects
		projects+=vsExtension
		return projects
	}
	
	override protected computeName(SubProjectConfig project) {
		switch project {
			case vsExtension: baseName + '.vscode-extension'
			default: super.computeName(project)
		}
	}
	
}