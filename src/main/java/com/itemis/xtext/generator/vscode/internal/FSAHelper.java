package com.itemis.xtext.generator.vscode.internal;

import org.eclipse.xtext.xtext.generator.model.IXtextGeneratorFileSystemAccess;
import org.eclipse.xtext.xtext.generator.model.TextFileAccess;

public class FSAHelper {

	public static void writeTo(TextFileAccess tfa, IXtextGeneratorFileSystemAccess fsa) {
		tfa.writeTo(fsa);
	}

}
