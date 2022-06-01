//
//  DataReportCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 11.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class DataReportCell: BaseCollectionViewCell {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var userCountDataLabel: UILabel!
    @IBOutlet weak var earningsLabel: UILabel!
    @IBOutlet weak var expensesLabel: UILabel!
    @IBOutlet weak var donationsLabel: UILabel!
    
    
    //MARK: - Variables
    
    static let identifier = "DataReportCell"
    
    private let imagineDataRequest = ImagineDataRequest()

    
    private var reportData: ReportData? {
        didSet {
            if let data = reportData {
                userCountDataLabel.text = String(data.userCount)
                earningsLabel.text = "$\(data.earnings)"
                expensesLabel.text = "$\(data.expenses)"
                donationsLabel.text = "$\(data.donations)"
                
            }
        }
    }
    
    //MARK: - Cell Lifecycle
    
    override func awakeFromNib() {
        getData()
        contentView.clipsToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.cornerRadius = Constants.cellCornerRadius
    }
    
    //MARK: - Get Data
    
    func getData() {
        imagineDataRequest.getReportData { (data) in
            if let data = data {
                self.reportData = data
            }
        }
    }
    
}
