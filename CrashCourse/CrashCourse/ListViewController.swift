//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

protocol FriendsService {
	func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void)
}

class ListViewController: UITableViewController {
	var user = User.shared
	var items = [Any]()
	
	var retryCount = 0
	var maxRetryCount = 0
	var shouldRetry = false
	
	var longDateStyle = false
	
	var fromReceivedTransfersScreen = false
	var fromSentTransfersScreen = false
	var fromCardsScreen = false
	
	var fromFriendsScreen = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
		
		if fromFriendsScreen {
			shouldRetry = true
			maxRetryCount = 2
		
		} else if fromCardsScreen {
			shouldRetry = false
			
		} else if fromSentTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = true


		} else if fromReceivedTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = false
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if tableView.numberOfRows(inSection: 0) == 0 {
			refresh()
		}
	}
	
	@objc private func refresh() {
		refreshControl?.beginRefreshing()
		if fromFriendsScreen {
			FriendsAPI.shared.loadFriends { [weak self] result in
				self?.handleAPIResult(result)
			}
		} else if fromCardsScreen {
			CardAPI.shared.loadCards { [weak self] result in
				self?.handleAPIResult(result)
			}
		} else if fromSentTransfersScreen || fromReceivedTransfersScreen {
			TransfersAPI.shared.loadTransfers { [weak self] result in
				self?.handleAPIResult(result)
			}
		} else {
			fatalError("unknown context")
		}
	}
	
	private func handleAPIResult<T>(_ result: Result<[T], Error>) {
		switch result {
		case let .success(items):
			self.retryCount = 0
			
			var filteredItems = items as [Any]
			if let transfers = items as? [Transfer] {
				if fromSentTransfersScreen {
					filteredItems = transfers.filter(\.isSender)
				} else {
					filteredItems = transfers.filter { !$0.isSender }
				}
			}
			
			self.items = filteredItems
			self.refreshControl?.endRefreshing()
			self.tableView.reloadData()
			
		case let .failure(error):
			if shouldRetry && retryCount < maxRetryCount {
				retryCount += 1
				
				refresh()
				return
			}
			
			retryCount = 0
			
			if fromFriendsScreen && User.shared?.isPremium == true {
				(UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.loadFriends { [weak self] result in
					switch result {
					case let .success(items):
						self?.items = items
						self?.tableView.reloadData()
						
					case let .failure(error):
						let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "Ok", style: .default))
						self?.present(alert, animated: true)
					}
					self?.refreshControl?.endRefreshing()
				}
			} else {
				let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .default))
				self.present(alert, animated: true)
				self.refreshControl?.endRefreshing()
			}
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		items.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = items[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ItemCell")
		cell.configure(item, longDateStyle: longDateStyle)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = items[indexPath.row]
		if let friend = item as? Friend {
			let vc = FriendDetailsViewController()
			vc.friend = friend
			navigationController?.pushViewController(vc, animated: true)
		} else if let card = item as? Card {
			let vc = CardDetailsViewController()
			vc.card = card
			navigationController?.pushViewController(vc, animated: true)
		} else if let transfer = item as? Transfer {
			let vc = TransferDetailsViewController()
			vc.transfer = transfer
			navigationController?.pushViewController(vc, animated: true)
		} else {
			fatalError("unknown item: \(item)")
		}
	}
}

extension UITableViewCell {
	func configure(_ item: Any, longDateStyle: Bool) {
		if let friend = item as? Friend {
			textLabel?.text = friend.name
			detailTextLabel?.text = friend.phone
		} else if let card = item as? Card {
			textLabel?.text = card.number
			detailTextLabel?.text = card.holder
		} else if let transfer = item as? Transfer {
			let numberFormatter = Formatters.number
			numberFormatter.numberStyle = .currency
			numberFormatter.currencyCode = transfer.currencyCode
			
			let amount = numberFormatter.string(from: transfer.amount as NSNumber)!
			textLabel?.text = "\(amount) • \(transfer.description)"
			
			let dateFormatter = Formatters.date
			if longDateStyle {
				dateFormatter.dateStyle = .long
				dateFormatter.timeStyle = .short
				detailTextLabel?.text = "Sent to: \(transfer.recipient) on \(dateFormatter.string(from: transfer.date))"
			} else {
				dateFormatter.dateStyle = .short
				dateFormatter.timeStyle = .short
				detailTextLabel?.text = "Received from: \(transfer.sender) on \(dateFormatter.string(from: transfer.date))"
			}
		} else {
			fatalError("unknown item: \(item)")
		}
	}
}
