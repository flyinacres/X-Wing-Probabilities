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
    @IBOutlet weak var hitsLabel: UILabel!
    
    
    var selectedAttackDice = 0
    var selectedDefenseDice = 0
    
    var attackOdds = 0.5
    var defenseOdds = 0.375
    var evadeTokens = 0.0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.canDisplayBannerAds = true

        let attackIndex = NSIndexPath(forRow: 0, inSection: 0)
        attackTable.selectRowAtIndexPath(attackIndex, animated: false, scrollPosition: UITableViewScrollPosition.None)
        let defenceIndex = NSIndexPath(forRow: 0, inSection: 0)
        defenceTable.selectRowAtIndexPath(defenceIndex, animated: false, scrollPosition: UITableViewScrollPosition.None)
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
        return 9
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Attack Cell")
        
        if tableView == attackTable {
            cell.backgroundColor = UIColor.redColor()
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
            cell.backgroundColor = UIColor.greenColor()
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
    
    
    // Make sure that all of the variables/display reflect the row that will be selected
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        var articleParams = ["type": "attack", "dice": "\(indexPath.section)", "focus": "false"]
        
        if tableView == attackTable {
           selectedAttackDice = indexPath.section
            attackOdds = 0.5
            if indexPath.row == 1 || indexPath.row == 3 {
                attackOdds = 0.75
                articleParams["focus"] = "true"
            }
            if indexPath.row == 2 || indexPath.row == 3 {
                // This adds in the probability for a reroll
                attackOdds += (1 - attackOdds) * attackOdds
                articleParams["lock"] = "true"
            }
        } else {
            articleParams["type"] = "defense"
            defenseOdds = 0.375
            if indexPath.row == 1 || indexPath.row == 3 {
                defenseOdds = 0.625
                articleParams["focus"] = "true"
            }
            evadeTokens = 0.0
            if indexPath.row == 2 || indexPath.row == 3 {
                evadeTokens = 1.0
                articleParams["evade"] = "true"
            }
            selectedDefenseDice = indexPath.section
        }
        
        Flurry.logEvent("User Selection", withParameters: articleParams);
        
        let percent = calcOdds(Double(selectedAttackDice+1), totalDefenseDice: Double(selectedDefenseDice))
        let percentString = NSString(format: "%.2f", percent * 100.0)
        
        percentLabel.text = percentString as String + "%"
        
        let hits = expectedHits(Double(selectedAttackDice+1), totalDefenseDice: Double(selectedDefenseDice))
        let hitsString = NSString(format: "%.2f", hits)
        
        hitsLabel.text = hitsString as String
        
        return indexPath
    }
    
    
    // A basic factorial calculator
    func factorial(n: Double) -> Double {
        if n >= 0 {
            return n == 0 ? 1 : n * self.factorial(n - 1)
        } else {
            return 0 / 0
        }
    }

    
    
    // For the specified parameters figure out the percent probability for the event, and the number of ways in which it can 
    // occur.
    func selectionTotal(odds: Double, selection: Double, total: Double) -> Double {
        let percent = pow(odds, Double(selection)) * pow((1-odds), Double(total - selection))
        let possibilities = factorial(total) / (factorial(selection) * factorial(total-selection))
        return percent * possibilities
    }
    
    
    // For a given number of attack and defense dice figure out what the odds of a hit are
    func calcOdds(totalAttackDice: Double, totalDefenseDice: Double) -> Double {
        var totalOdds = 0.0
        
        // Check all possible hit totals
        for var hits = 1.0; hits <= totalAttackDice; hits += 1.0 {
            var hitTotal = 0.0
            
            // Don't count the probabilities when the hits are <= evade tokens as no hit can happen
            if hits > evadeTokens {
                // Calculate the odds of getting the specified number of hits, no rerolls
                hitTotal = selectionTotal(attackOdds, selection: hits, total: totalAttackDice)
                
                for var evades = 0.0; evades <= totalDefenseDice; evades += 1.0 {
                    // if hits is not greater than the number of evades + evade tokens there cannot be a hit
                    if evades + evadeTokens < hits {
                        let evadeTotal = selectionTotal(defenseOdds, selection: evades, total: totalDefenseDice)
                        
                        totalOdds = totalOdds + hitTotal * evadeTotal
                    }
                }
            }
        }
        
        return totalOdds
    }
    

    
    // The same algorithm as calcOdds, except for one small tweak: multiply each term by the number of hits
    // that would occur (hits - evades) to weigh the result properly for expected hits/damage
    func expectedHits(totalAttackDice: Double, totalDefenseDice: Double) -> Double {
        var totalHits = 0.0
        
        // Check all possible hit totals
        for var hits = 1.0; hits <= totalAttackDice; hits += 1.0 {
            var hitTotal = 0.0
            
            // Don't count the probabilities when the hits are <= evade tokens as no hit can happen
            if hits > evadeTokens {
                // Calculate the odds of getting the specified number of hits, no rerolls
                hitTotal = selectionTotal(attackOdds, selection: hits, total: totalAttackDice)
                
                for var evades = 0.0; evades <= totalDefenseDice; evades += 1.0 {
                    // if hits is not greater than the number of evades + evade tokens there cannot be a hit
                    if evades + evadeTokens < hits {
                        let evadeTotal = selectionTotal(defenseOdds, selection: evades, total: totalDefenseDice)
                        
                        totalHits = totalHits + hitTotal * evadeTotal * (hits - (evades + evadeTokens))
                    }
                }
            }
        }
        
        return totalHits
    }

}

