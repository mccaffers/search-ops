//
//  SwiftUIView.swift
//  
//
//  Created by Ryan McCaffery on 16/07/2023.
//

import SwiftUI

import Foundation
import RealmSwift

@available(iOS 15, *)
public class ApplicationSettings : Object {

	@Persisted(primaryKey: true) public var id: UUID = UUID()
	
	// Search Settings
	@Persisted public var maximumDocumentsPerPage : Int = 25
	@Persisted public var requestTimeout : Int = 15

}

@available(iOS 15.0, *)
public class SettingsDatatManager: ObservableObject {
		
		@Published
		public var settings: ApplicationSettings? = nil
		
		public init() {
				self.settings = ReadServer()
		}
	
	public func setDocumentsPerPage(input: Int) {
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				self.settings?.maximumDocumentsPerPage = input
			}
		}
	}
	
	public func setTimeoiut(input: Int) {
		if let realm = RealmManager.getRealm() {
			try! realm.write {
				self.settings?.requestTimeout = input
			}
		}
	}
		
		private func ReadServer() -> ApplicationSettings? {
				 
				if let realm = RealmManager.getRealm() {
						var settingsObj = realm.objects(ApplicationSettings.self)
					if settingsObj.count == 1 {
						return settingsObj.first
					} else {
						let initialSettings = ApplicationSettings()
						Update(item:initialSettings)
							return initialSettings
					}
				} else {
					return nil
				}
		}
		
		private func Update(item: ApplicationSettings) {
				if let realm = RealmManager.getRealm() {
						try! realm.write {
								realm.add(item, update: Realm.UpdatePolicy.modified)
						}
				}
		}
		

}
