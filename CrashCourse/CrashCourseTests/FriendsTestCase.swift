//	
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import CrashCourse

/*
		* Dummy 								=> Utilizado em testes e geralmente não faz nada
		* Spy 								=> Utilizado para captura eventos (callCount)
													Simular comportamentos
													Spy geralmente são Stubs
		* Stub								=> Não capturam eventos. Não são Spy
													Eles apenas tem os resultados predefinidos.
 
		* Property Injection 			=> É muito útil ao lidar com código legado.
													Tiramos as instancias e realizamos "Injeção de Propriedade"
		* Injection Dependency			=> Para novo código devemos utilizar a dependencia no inicializador
		* loadViewIfNeeded				=> Método para carregar a ViewController da View.
													loadView / viewDidLoad
		* beginAppearanceTransition	=> Método para carregar as funções de aparecer/desaparecer ViewController.
													viewWillAppear / viewWillDisappear / viewDidAppear / viewDidDisappear
 */

class FriendsTestCase: XCTestCase {
	
	func test_viewDidLoad_doesNotLoadFriendsFromAPI() {
		let service = FriendsServiceSpy()
		let sut = FriendsViewController(service: service)
		
		sut.loadViewIfNeeded()

		XCTAssertEqual(service.loadFriendsCallCount, 0)
	}
	
	func test_viewWillAppear_loadsFriendsFromAPI() {
		let service = FriendsServiceSpy()
		let sut = FriendsViewController(service: service)
		
		sut.simulateViewWillAppear()

		XCTAssertEqual(service.loadFriendsCallCount, 1)
	}
	
	func test_viewWillAppear_successfulAPIResponse_showsFriends() {
		let friend1 = Friend(id: UUID(), name: "Friend1", phone: "Phone1")
		let friend2 = Friend(id: UUID(), name: "Friend2", phone: "Phone2")
		let service = FriendsServiceSpy(result: [friend1, friend2])
		let sut = FriendsViewController(service: service)
		
		sut.simulateViewWillAppear()

		sut.assert(isRendering: [friend1, friend2])
	}
	
	func test_viewWillAppear_failedAPIResponse_3times_showsErro() {
		let service = FriendsServiceSpy(results: [
			.failure(AnyError(errorDescription: "1st error")),
			.failure(AnyError(errorDescription: "2nd error")),
			.failure(AnyError(errorDescription: "3rd error")),
		])
		let sut = TestableFriendsViewController(service: service)
		
		sut.simulateViewWillAppear()

		XCTAssertEqual(sut.errorMessage(), "3rd error")
	}
	
	func test_viewWillAppear_successAfterFailedAPIResponse_1times_showsFriends() {
		let friend = Friend(id: UUID(), name: "a friend", phone: "a phone")
		let service = FriendsServiceSpy(results: [
			.failure(AnyError(errorDescription: "1st error")),
			.success([friend]),
		])
		let sut = TestableFriendsViewController(service: service)
		
		sut.simulateViewWillAppear()

		sut.assert(isRendering: [friend])
	}
	
	func test_viewWillAppear_successAfterFailedAPIResponse_2times_showsFriends() {
		let friend = Friend(id: UUID(), name: "a friend", phone: "a phone")
		let service = FriendsServiceSpy(results: [
			.failure(AnyError(errorDescription: "1st error")),
			.failure(AnyError(errorDescription: "2nd error")),
			.success([friend]),
		])
		let sut = TestableFriendsViewController(service: service)
		
		sut.simulateViewWillAppear()

		sut.assert(isRendering: [friend])
	}
	
	func test_friendSelection_showsFriendDetails() throws {
		let friend = Friend(id: UUID(), name: "a friend", phone: "a phone")
		let service = FriendsServiceSpy(results: [
			.success([friend]),
		])
		let sut = FriendsViewController(service: service)
		let navigation = NonAnimatedUINavigationController(rootViewController: sut)
		
		sut.simulateViewWillAppear()
		sut.selectFriend(at: 0)
		
		let detail = try XCTUnwrap(navigation.topViewController as? FriendDetailsViewController)
		
		XCTAssertEqual(detail.friend, friend)
	}
	
}

class FriendsServiceSpy: FriendsService {
	private(set) var loadFriendsCallCount = 0
	private var results: [Result<[Friend], Error>]
	
	init(result: [Friend] = []) {
		self.results = [.success(result)]
	}
	
	init(results: [Result<[Friend], Error>]) {
		self.results = results
	}
	
	func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
		loadFriendsCallCount += 1
		completion(results.removeFirst())
	}
	
}

private struct AnyError: LocalizedError {
	var errorDescription: String?
}

private class TestableFriendsViewController: FriendsViewController {
	var presentVC: UIViewController?
	
	override func present(_ vc: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
		presentVC = vc
	}
	
	func errorMessage() -> String? {
		let alert = presentVC as? UIAlertController
		return alert?.message
	}
}

private class NonAnimatedUINavigationController: UINavigationController {
	override func pushViewController(_ viewController: UIViewController, animated: Bool) {
		super.pushViewController(viewController, animated: false)
	}
}

private extension FriendsViewController {
	
	private var friendsSection: Int { 0 }
	
	func simulateViewWillAppear() {
		loadViewIfNeeded()
		beginAppearanceTransition(true, animated: false)
	}
	
	func numberOfFriends() -> Int {
		tableView.numberOfRows(inSection: friendsSection)
	}
	
	func friendName(at row: Int) -> String? {
		friendCell(at: row)?.textLabel?.text
	}
	
	func friendPhone(at row: Int) -> String? {
		friendCell(at: row)?.detailTextLabel?.text
	}
	
	private func friendCell(at row: Int) -> UITableViewCell? {
		let indexPath = IndexPath(row: row, section: friendsSection)
		return tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
	}
	
	func selectFriend(at row: Int) {
		let indexPath = IndexPath(row: row, section: friendsSection)
		tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
	}
	
	func assert(isRendering friends: [Friend]) {
		XCTAssertEqual(numberOfFriends(), friends.count)
		
		for (index, friend) in friends.enumerated() {
			XCTAssertEqual(friendName(at: index), friend.name)
			XCTAssertEqual(friendPhone(at: index), friend.phone)
		}
	}
	
}
