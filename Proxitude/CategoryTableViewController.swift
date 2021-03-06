//
//  CategoryTableViewController.swift
//  Proxitude
//
//  Created by Michael Liu on 11/28/16.
//  Copyright © 2016 Michael Liu. All rights reserved.
//

import UIKit
import Firebase
enum QueryType{
    case category
    case myItem
}

class CategoryTableViewController: UITableViewController {
    
    var items = [Item]()
    var queryType: QueryType?
    var category:String?
    let itemCellIdentifier = "itemCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        query()
        navigationController?.masterNav()
        navigationController?.navigationItem.title = category
        navigationController?.navigationBar.tintColor = UIColor.white
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ItemTableViewCell = tableView.dequeueReusableCell(withIdentifier: itemCellIdentifier, for: indexPath) as! ItemTableViewCell
        cell.setItem(item: items[indexPath.row])
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        return cell
    }
    
    func setup(){
        tableView.register(UINib.init(nibName: "ItemTableViewCell", bundle: nil), forCellReuseIdentifier: itemCellIdentifier)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let itemDetailController:ItemDetailViewController = storyboard.instantiateViewController(withIdentifier: "itemDetail") as! ItemDetailViewController
        itemDetailController.item = items[indexPath.row]
        navigationController?.pushViewController(itemDetailController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if queryType == .myItem{
            let deleteAction  = UITableViewRowAction(style: .default, title: "Delete") { (rowAction, indexPath) in
                let item = self.items[indexPath.row]
                item.deleteItem(itemID: item.itemId)
            }
            deleteAction.backgroundColor = UIColor.red
            return [deleteAction]
        }
        return nil
    }
    
    func query(){
        if queryType! == .category {
            queryByCategory(category: category!, limit: 100)
        }else{
            let query = Query()
            if let user = FIRAuth.auth()?.currentUser {
                for profile in user.providerData {
                    query.queryItemByUser(user: profile.email!).observe(.value, with: { snapshot in
                        self.items = query.getItems(snapshot: snapshot,sell:true)
                        self.tableView.reloadData()
                    })
                }
            }
        }
    }
    
    func queryByCategory(category:String,limit:Int){
        let ref = FIRDatabase.database().reference().child("colleges/wheaton-college").child("tags").child(category)
        ref.queryLimited(toLast: UInt(limit)).observe(.value, with: {
            snapshot in
            for child:FIRDataSnapshot in snapshot.children.allObjects as! [FIRDataSnapshot]{
                self.getItem(itemId: child.key)
            }
        })
    }
    
    func getItem(itemId:String){
        FIRDatabase.database().reference().child("colleges/wheaton-college").child("items").child(itemId).observeSingleEvent(of: .value, with: {
            snapshot in
            let item = Item()
            for elem:FIRDataSnapshot in snapshot.children.allObjects as! [FIRDataSnapshot]{
                switch elem.key {
                case "name":
                    item.name = elem.value as! String!
                    break
                case "price":
                    item.price = elem.value as! String!
                    break
                case "detail":
                    item.detail = elem.value as! String!
                    break
                case "user":
                    item.user = elem.value as! String!
                    break
                case "thumbnail":
                    item.thumbnail = elem.value as! String!
                    break
                case "images":
                    for url in elem.value as! [String:String] {
                        item.imagesURL.insert(url.value, at: item.imagesURL.count)
                    }
                    break
                case "date":
                    item.date = elem.value as! String!
                    break
                case "tags":
                    break
                case "sell":
                    break
                default:
                    let tuple = ("\(elem.key)", "\(elem.value!)")
                    item.fields.insert(tuple, at: item.fields.count)
                    break
                }
            }
            self.items.insert(item, at: self.items.count)
            self.tableView.reloadData()
        })
    }

}
