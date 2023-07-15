//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/6/25.
//

import Foundation

public var appBuild: String = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
public var appVersion: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

