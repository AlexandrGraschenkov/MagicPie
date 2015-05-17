//
//  PieView2.swift
//  MagicPie
//
//  Created by Alexander on 17.05.15.
//  Copyright (c) 2015 Alexandr Corporation. All rights reserved.
//

import UIKit

class PieView2: UIView {
    
    override class func layerClass() -> AnyClass {
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
        
        let tap = UITapGestureRecognizer(target: self, action: "handleTap:")
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tap)
    }
    
    func handleTap(tap: UITapGestureRecognizer) {
        if tap.state != UIGestureRecognizerState.Ended {
            return
        }
        
        let pos = tap.locationInView(tap.view)
        
        if let tappedElem = pieLayer.pieElemInPoint(pos) {
            let newIdx = find(pieLayer.values as! [PieElement], tappedElem)
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
            for (idx, obj) in enumerate(self.pieLayer.values) {
                let elem = obj as! PieElement
                elem.centrOffset = idx == self.selectedIdx ? 20 : 0
            }
        }
    }
}
