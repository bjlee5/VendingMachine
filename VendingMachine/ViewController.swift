//
//  ViewController.swift
//  VendingMachine
//
//  Created by Pasan Premaratne on 12/1/16.
//  Copyright © 2016 Treehouse Island, Inc. All rights reserved.
//

import UIKit

fileprivate let reuseIdentifier = "vendingItem"
fileprivate let screenWidth = UIScreen.main.bounds.width

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
     
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    
    let vendingMachine: VendingMachine 
    var currentSelection: VendingSelection?
    
    required init?(coder aDecoder: NSCoder) {
        do {
            let dictionary = try PlistConverter.dictionary(fromFile: "VendingInventory", ofType: "plist")
            let inventory = try InventoryUnarchiver.vendingInventory(fromDictionary: dictionary)
            self.vendingMachine = FoodVendingMachine(inventory: inventory)
        } catch let error {
            fatalError("\(error)")
        }
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCollectionViewCells()
        updateDisplayWith(balance: vendingMachine.amountDeposited, totalPrice: 0, itemPrice: 0, itemQuantity: 1)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup

    func setupCollectionViewCells() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        
        let padding: CGFloat = 10
        let itemWidth = screenWidth/3 - padding
        let itemHeight = screenWidth/3 - padding
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: Vending Machine
    
    @IBAction func purchase() {
        if let currentSelection = currentSelection {
            do {
                try vendingMachine.vend(Int(quantityStepper.value), selection: currentSelection)
                updateDisplayWith(balance: vendingMachine.amountDeposited, totalPrice: 0.00, itemPrice: 0.00, itemQuantity: 0)
            } catch VendingError.outOfStock {
                showAlert(title: "Out of Stock", message: "Vending machine is out of this item, please select   another")
            } catch VendingError.invalidSelection {
                showAlert(title: "Invalid Selection", message: "You've selected an invalid item, please try again")
            } catch VendingError.insufficientFunds {
                showAlert(title: "Insufficient Funds", message: "You're fucking broke, G.")

            } catch let error {
                fatalError("\(error)")
            }
            
            if let indexPath = collectionView.indexPathsForSelectedItems?.first {
                collectionView.deselectItem(at: indexPath, animated: true)
                updateCell(having: indexPath, selected: false)
            }
        }
    }
    
    func updateDisplayWith(balance: Double? = nil, totalPrice: Double? = nil, itemPrice: Double? = nil, itemQuantity: Int? = nil) {
        
        if let balanceValue = balance {
            balanceLabel.text = "$\(balanceValue)"
        }
        if let totalValue = totalPrice {
            totalLabel.text = "$\(totalValue)"
        }
        
        if let priceValue = itemPrice {
            priceLabel.text = "$\(priceValue)"
        }
        
        if let quantity = itemQuantity {
            quantityLabel.text = "\(quantity)"
        }
        
    }
    
    func updateTotalPrice(for item: VendingItem) {
        let totalPrice = item.price * quantityStepper.value
        updateDisplayWith(totalPrice: totalPrice)
    }
    
    @IBAction func updateStepper(_ sender: UIStepper) {
        let quantity = Int(sender.value)
        updateDisplayWith(itemQuantity: quantity)
        
        if let currentSelection = currentSelection, let item = vendingMachine.item(forSelection: currentSelection) {
            updateTotalPrice(for: item)
        }
        
    }
    @IBAction func depositFunds(_ sender: Any) {
        vendingMachine.deposit(5.00)
        updateDisplayWith(balance: vendingMachine.amountDeposited)
    }
    
    // Show Alert Controller //
    
    func showAlert(title: String, message: String) {
        let alertTitle = title
        let messageTitle = message
        let alertController = UIAlertController(title: alertTitle, message: messageTitle, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: dismissAction))
        present(alertController, animated: true, completion: nil)
    }
    
    func dismissAction(alert: UIAlertAction) -> Void {
        updateDisplayWith(balance: vendingMachine.amountDeposited, totalPrice: 0, itemPrice: 0, itemQuantity: 1)
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? VendingItemCell else { fatalError() }
        
        let item = vendingMachine.selection[indexPath.row]
        cell.iconView.image = item.icon()
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
        
        quantityStepper.value = 1
        updateDisplayWith(totalPrice: 0, itemQuantity: 1)
        
        currentSelection = vendingMachine.selection[indexPath.row]
        if let currentSelection = currentSelection, let item = vendingMachine.item(forSelection: currentSelection) {
        
        let totalPrice = item.price * quantityStepper.value
        updateDisplayWith(totalPrice: totalPrice, itemPrice: item.price)
        
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func updateCell(having indexPath: IndexPath, selected: Bool) {
        
        let selectedBackgroundColor = UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0)
        let defaultBackgroundColor = UIColor(red: 27/255.0, green: 32/255.0, blue: 36/255.0, alpha: 1.0)
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = selected ? selectedBackgroundColor : defaultBackgroundColor
        }
    }
    
    
}

