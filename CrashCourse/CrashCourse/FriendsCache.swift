//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

class FriendsCache {	
	private var friends: [Friend]!
		
	func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
		completion(.success(friends))
	}
	
	func save(_ newFriends: [Friend]) {
		friends = newFriends
	}
}
