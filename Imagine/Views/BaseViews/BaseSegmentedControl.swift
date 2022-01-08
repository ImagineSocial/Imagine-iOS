//
//  BaseSegmentedControl.swift
//  Imagine
//
//  Created by Don Malte on 27.11.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

protocol BaseSegmentControlDelegate: class {
    func segmentChanged(to index: Int, direction: UIPageViewController.NavigationDirection)
}

class BaseSegmentedControlView: UIView {
    
    
    var segmentedControl: BaseSegmentedControl
    let indicatorView = BaseView(backgroundColor: .label)

    var lastIndex = 0
    
    var segmentIndicatorCenterXConstraint: NSLayoutConstraint?
    var segmentIndicatorWidthConstraint: NSLayoutConstraint?
    
    weak var delegate: BaseSegmentControlDelegate?
    
    init(items: [Any], tintColor: UIColor = .imagineColor, font: UIFont? = UIFont.standard(), selectedItem: Int = 0) {
        self.segmentedControl = BaseSegmentedControl(items: items, tintColor: tintColor, font: font, selectedItem: selectedItem)
        
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        setSegmentedIndicatorView()
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
    }
    
    required init?(coder: NSCoder) {
        self.segmentedControl = BaseSegmentedControl(items: [])
        super.init(coder: coder)
    }
    
    func setSegmentedIndicatorView() {
        addSubview(segmentedControl)
        addSubview(indicatorView)
        
        segmentedControl.fillSuperview()
        
        let image = UIImage()
        segmentedControl.setBackgroundImage(image, for: .normal, barMetrics: .default)
        segmentedControl.setDividerImage(image, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.standard(with: .medium, size: 15)!, NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel], for: .normal)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.font : UIFont.standard(with: .medium, size: 16)!, NSAttributedString.Key.foregroundColor: UIColor.label], for: .selected)
        
        indicatorView.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 3).isActive = true
        indicatorView.heightAnchor.constraint(equalToConstant: 2).isActive = true
        indicatorView.layer.cornerRadius = 1
        
        guard let title = segmentedControl.titleForSegment(at: 0) else { return }
        
        segmentIndicatorWidthConstraint = indicatorView.widthAnchor.constraint(equalToConstant: getWidth(for: title))
        segmentIndicatorWidthConstraint!.isActive = true
        segmentIndicatorCenterXConstraint = indicatorView.centerXAnchor.constraint(equalToSystemSpacingAfter: segmentedControl.centerXAnchor, multiplier: getMultiplier())
        segmentIndicatorCenterXConstraint!.isActive = true
        
        segmentedControlChanged()
    }

    @objc func segmentedControlChanged() {
        let index = segmentedControl.selectedSegmentIndex

        guard let title = segmentedControl.titleForSegment(at: index) else { return }
        
        delegate?.segmentChanged(to: index, direction: index > lastIndex ? .forward : .reverse)
        
        self.segmentIndicatorWidthConstraint!.constant = getWidth(for: title)
        self.segmentIndicatorCenterXConstraint = self.segmentIndicatorCenterXConstraint!.setMultiplier(multiplier: getMultiplier())
        
        UIView.animate(withDuration: 0.3, animations: {
            self.layoutIfNeeded()
        }) { (_) in
            self.lastIndex = index
        }
    }
    
    private func getWidth(for title: String) -> CGFloat {
        CGFloat(15 + title.count * 8)
    }
    
    private func getMultiplier() -> CGFloat {
        CGFloat(1 / (CGFloat(segmentedControl.numberOfSegments) / CGFloat(3.0 + CGFloat(segmentedControl.selectedSegmentIndex - 1) * 2.0)))
    }
}

class BaseSegmentedControl: UISegmentedControl {
    
    init(items: [Any], tintColor: UIColor = .imagineColor, font: UIFont? = UIFont.standard(), selectedItem: Int = 0) {
        super.init(items: items)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let font: [AnyHashable : Any] = [NSAttributedString.Key.font : font as Any]
        self.setTitleTextAttributes(font as? [NSAttributedString.Key : Any], for: .normal)
        self.tintColor = tintColor
        self.selectedSegmentIndex = selectedItem
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
