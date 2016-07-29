package com.itemis.xtext.generator.vscode;

import org.eclipse.xtext.xtext.generator.model.project.ISubProjectConfig;
import org.eclipse.xtext.xtext.generator.model.project.IXtextProjectConfig;

public interface IVSCodeProjectConfig extends IXtextProjectConfig {
	ISubProjectConfig getVsExtension();
}
