//
//  ViewController.swift
//  xWing
//
//  Created by Ronald Fischer on 11/7/15.
//  Copyright © 2015 qpiapps. All rights reserved.
//

import UIKit
import iAd


class ViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var attackTable: UITableView!
    @IBOutlet weak var defenceTable: UITableView!
    @IBOutlet weak var percentLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.canDisplayBannerAds = true
//        print("1x1 odds = \(calcOdds(1, totalDefenseDice: 1))")
//        print("2x1 odds = \(calcOdds(2, totalDefenseDice: 1))")
//        print("1x2 odds = \(calcOdds(1, totalDefenseDice: 2))")
//        print("2x2 odds = \(calcOdds(2, totalDefenseDice: 2))")
//
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // fixed font style. use custom view (UILabel) if you want something different
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var actualSection = section
        // Must have at least one attack die
        if tableView == attackTable {
            actualSection = section + 1
        }
        
        var header = ""
        var plural = "Dice"
        if actualSection == 1 {
            plural = "Die"
        }
        if tableView == attackTable {
            header = "\(actualSection) Attack \(plural)"
        } else {
            header = "\(actualSection) Defense \(plural)"
        }
        return header
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 7
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Attack Cell")
        
        if tableView == attackTable {
            switch indexPath.row {
                case 0:
                    cell.textLabel?.text = "no modifiers"
                case 1:
                    cell.textLabel?.text = "focus"
                case 2:
                    cell.textLabel?.text = "target lock"
                case 3:
                    cell.textLabel?.text = "focus + lock"
                default:
                    cell.textLabel?.text = "unknown"
            }
        } else {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "no modifiers"
            case 1:
                cell.textLabel?.text = "focus"
            case 2:
                cell.textLabel?.text = "evade"
            case 3:
                cell.textLabel?.text = "focus + evade"
            default:
                cell.textLabel?.text = "unknown"
            }
        }
        
        return cell
    }
    
    var selectedAttackDice = 1
    var selectedDefenseDice = 1
    
    // Make sure that all of the variables/display reflect the row that will be selected
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        if tableView == attackTable {
            selectedAttackDice = indexPath.section
        } else {
            selectedDefenseDice = indexPath.section
        }
        
        let percent = calcOdds(Double(selectedAttackDice+1), totalDefenseDice: Double(selectedDefenseDice))
        let percentString = NSString(format: "%.2f", percent * 100.0)
        
        percentLabel.text = percentString as String + "%"
        
        return indexPath
    }
    
    func factorial(n: Double) -> Double {
        if n >= 0 {
            return n == 0 ? 1 : n * self.factorial(n - 1)
        } else {
            return 0 / 0
        }
    }
    
    func calcOdds(totalAttackDice: Double, totalDefenseDice: Double) -> Double {
        var totalOdds = 0.0
        
        for var hits = 1.0; hits <= totalAttackDice; hits += 1.0 {
            // Since this is 50/50 when unmodified it could be moved out of the loop.
            let hitPercentage = pow(0.5, Double(hits))
            //let hitTotal = factorial(totalAttackDice / factorial(hits) * factorial(totalAttackDice-hits))
            
            for var evades = 0.0; evades <= totalDefenseDice; evades += 1.0 {
                if evades < hits {
                    let evadePercentage = pow(0.375, Double(evades)) * pow(0.625, Double(totalDefenseDice - evades))
                    //let evadeTotal = factorial(totalDefenseDice / factorial(evades) * factorial(totalDefenseDice-evades))
                    //totalOdds = totalOdds + (hitTotal * hitPercentage * evadeTotal * evadePercentage)
                    totalOdds = totalOdds + (hitPercentage * evadePercentage)
                }
            }
        }
        

        return totalOdds
    }
    


}

