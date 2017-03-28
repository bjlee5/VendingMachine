//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by MacBook Air on 3/27/17.
//  Copyright © 2017 Treehouse Island, Inc. All rights reserved.
//

import Foundation
import UIKit

enum VendingSelection: String {
    case soda
    case dietSoda
    case chips
    case cookie
    case sandwich
    case wrap
    case candyBar
    case popTart
    case water
    case fruitJuice
    case sportsDrink
    case gum
    
    func icon() -> UIImage {
        if let image = UIImage(named: self.rawValue) {
        return image
    } else {
        let image = #imageLiteral(resourceName: "default")
        return image
        }
    }
}

protocol VendingItem {
    var price: Double { get }
    var quantity: Int { get set }
}


protocol VendingMachine {
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: VendingItem] { get set }
    var amountDeposited: Double { get set }
    
    init(inventory: [VendingSelection: VendingItem])
    func vend(_ quantity: Int, selection: VendingSelection) throws
    func deposit(_ money: Double)
    func item(forSelection selection: VendingSelection) -> VendingItem?
    
}

struct Item: VendingItem {
    let price: Double
    var quantity: Int
}

enum ErrorType: Error {
    case invalidResource
    case conversionError
    case invalidSelection
}


class PlistConverter {
    static func dictionary(fromFile name: String, ofType type: String) throws -> [String: AnyObject] {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            throw ErrorType.invalidResource
        }
        
        guard let dictionary = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            throw ErrorType.conversionError
        }
    
        return dictionary
    }
}

class InventoryUnarchiver {
    static func vendingInventory(fromDictionary dictionary: [String: AnyObject]) throws -> [VendingSelection: VendingItem] {
        
    var inventory: [VendingSelection: VendingItem] = [:]
     
        for (key, value) in dictionary {
            if let itemDictionary = value as? [String: Any], let price = itemDictionary["price"] as? Double, let quantity = itemDictionary["quantity"] as? Int {
                let item = Item(price: price, quantity: quantity)
                
                guard let selection = VendingSelection(rawValue: key) else {
                    throw ErrorType.invalidSelection
                }
                
                inventory.updateValue(item, forKey: selection)
            }
        }
        return inventory
    }
}

enum VendingError: Error {
    case insufficientFunds
    case invalidSelection
    case outOfStock
}


class FoodVendingMachine: VendingMachine {
    let selection: [VendingSelection] = [.soda, .dietSoda, .chips, .cookie, .sandwich, .wrap, .candyBar, .popTart, .water, .fruitJuice, .sportsDrink, .gum]
    var inventory: [VendingSelection : VendingItem]
    var amountDeposited: Double = 10.00
    
    required init(inventory: [VendingSelection: VendingItem]) {
        self.inventory = inventory
    }
    
    func vend(_ quantity: Int, selection: VendingSelection) throws {
        guard var item = inventory[selection] else {
            throw VendingError.invalidSelection }
        guard item.quantity >= quantity else {
            throw VendingError.outOfStock }
        
        let totalPrice = item.price * Double(quantity)
            if amountDeposited >= totalPrice {
                amountDeposited -= totalPrice
                item.quantity -= quantity
                
                inventory.updateValue(item, forKey: selection)
            } else {
                throw VendingError.insufficientFunds
        }
    }
    
    func deposit(_ money: Double) {
        amountDeposited += money
    }
    
    func item(forSelection selection: VendingSelection) -> VendingItem? {
        return inventory[selection]
    }
}
