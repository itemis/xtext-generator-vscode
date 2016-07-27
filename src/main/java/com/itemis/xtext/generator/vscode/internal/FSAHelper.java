/*******************************************************************************
 * Copyright (c) 2016 itemis AG (http://www.itemis.de) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package com.itemis.xtext.generator.vscode.internal;

import org.eclipse.xtext.xtext.generator.model.IXtextGeneratorFileSystemAccess;
import org.eclipse.xtext.xtext.generator.model.TextFileAccess;

/**
 * This helper class only exists as a workaround of an Xtend bug, since direct use of the
 * writeTo method within VSCodeExtensionFragment yields an compile error. 
 */
public class FSAHelper {
	public static void writeTo (TextFileAccess tfa, IXtextGeneratorFileSystemAccess fsa) {
		tfa.writeTo(fsa);
	}
}
