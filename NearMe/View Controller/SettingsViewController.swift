//
//  SettingsViewController.swift
//  NearMe
//
//  Created by Xiang Yu on 10/17/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate {
    func settingsViewController(settingsViewController: SettingsViewController, didUpdateFilters filters: Settings)
}

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: SettingsViewControllerDelegate!
    
    var tableData = SettingsTable()
    //index is section id, content is selected row indices
    
    let HeaderViewIdentifier = "TableViewHeaderView"
    
    private func initData() {
        tableData.removeAll()
        
        let distanceIndex = Settings.globalSettings.distanceIndex
        let sortByChoicesIndex = Settings.globalSettings.sortByIndex
        
        tableData.append((.Distance, [Settings.distanceChoices[distanceIndex]]))
        tableData.append((.SortBy, [Settings.sortByChoices[sortByChoicesIndex]]))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initData()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //tableView.backgroundColor = UIColor.white
        
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: HeaderViewIdentifier)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderViewIdentifier)!

        header.textLabel?.text = tableData[section].0.rawValue

        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].settings.count
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let sectionId = tableData[indexPath.section].sectionId
        if tableView.cellForRow(at: indexPath)?.accessoryType == UITableViewCellAccessoryType.detailButton {
            
            if sectionId == .Distance {
                tableData[indexPath.section].settings = Settings.distanceChoices
            }
            else if sectionId == .SortBy {
                tableData[indexPath.section].settings = Settings.sortByChoices
            }
        }
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionId = tableData[indexPath.section].sectionId
        
        // expand table section
        if tableView.cellForRow(at: indexPath)?.accessoryType == UITableViewCellAccessoryType.detailButton {
            
            if sectionId == .Distance {
                tableData[indexPath.section].settings = Settings.distanceChoices
            }
            else if sectionId == .SortBy {
                tableData[indexPath.section].settings = Settings.sortByChoices
            }
        } else { // fold section
            let rowsCount = self.tableView.numberOfRows(inSection: indexPath.section)
            for i in 0..<rowsCount  {
                let curIdxPath = IndexPath(row: i, section: indexPath.section)
                let cell = self.tableView.cellForRow(at: curIdxPath)
                
                cell?.accessoryType = UITableViewCellAccessoryType.none
            }
            
            tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.checkmark
            
            let selectedCellData = tableData[indexPath.section].settings[indexPath.row]
            tableData[indexPath.section].settings.removeAll()
            tableData[indexPath.section].settings.append(selectedCellData)
            
            if tableData[indexPath.section].0 == .Distance {
                Settings.globalSettings.distanceIndex = indexPath.row
            } else if tableData[indexPath.section].0 == .SortBy {
                Settings.globalSettings.sortByIndex = indexPath.row
            }
        }
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableData[indexPath.section].0 {
        case .Distance, .SortBy:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
            
            cell.textLabel?.text = tableData[indexPath.section].1[indexPath.row]["name"]
            
            if tableData[indexPath.section].settings.count == 1 {
                cell.accessoryType = UITableViewCellAccessoryType.detailButton
            } else if tableData[indexPath.section].settings.count > 1 {
                var selected = false;
                if tableData[indexPath.section].0 == .Distance {
                    selected = Settings.globalSettings.distanceIndex == indexPath.row
                } else if tableData[indexPath.section].0 == .SortBy {
                    selected = Settings.globalSettings.sortByIndex == indexPath.row
                }
                
                cell.accessoryType = selected ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
            }
            
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
            
            cell.switchLabel.text = tableData[indexPath.section].1[indexPath.row]["name"]
            //cell.delegate = self
            
            //cell.onSwitch.isOn = switchStates[indexPath] ?? false
            
            return cell
        }
    }
}
