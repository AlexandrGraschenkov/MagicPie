//
//  PieView2.swift
//  MagicPie
//
//  Created by Alexander on 17.05.15.
//  Copyright (c) 2015 Alexandr Corporation. All rights reserved.
//

import UIKit

class PieView2: UIView {
    
    override class var layerClass: AnyClass {
        return PieLayer.self
    }
    
    var pieLayer: PieLayer {
        return layer as! PieLayer
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    //MARK: - private
    private var selectedIdx: Int?
    
    private func commonInit() {
        pieLayer.maxRadius = 100;
        pieLayer.minRadius = 20;
        pieLayer.animationDuration = 0.6
        pieLayer.startAngle = 360
        pieLayer.endAngle = 0
        pieLayer.showTitles = ShowTitlesAlways
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(tap:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tap)
    }
    
    @objc private func handleTap(tap: UITapGestureRecognizer) {
        if tap.state != .ended {
            return
        }
        
        let pos = tap.location(in: tap.view)
        
        if let tappedElem = pieLayer.pieElem(in: pos) {
            let newIdx = pieLayer.values.firstIndex(of: tappedElem)
            if newIdx == selectedIdx {
                selectedIdx = nil
            } else {
                selectedIdx = newIdx
            }
        }
        
        self.animateChanges()
    }
    
    private func animateChanges() {
        PieElement.animateChanges {
            for (idx, elem) in self.pieLayer.values.enumerated() {
                elem.centrOffset = idx == self.selectedIdx ? 20 : 0
            }
        }
    }
}
