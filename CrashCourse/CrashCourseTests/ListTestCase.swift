//	
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import CrashCourse

class ListTestCase: XCTestCase {

	func test() {
		let sut = ListViewController()
		sut.user = User(id: UUID(), name: "a friend", isPremium: true)
		sut.fromFriendsScreen = true
		
		sut.loadViewIfNeeded()
		sut.beginAppearanceTransition(true, animated: false)
		
		XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 1)
	}
	
}
