//
//  Example2SwiftController.swift
//  MagicPie
//
//  Created by Alexander on 17.05.15.
//  Copyright (c) 2015 Alexandr Corporation. All rights reserved.
//

import UIKit

class Example2SwiftController: UIViewController {
    
    init() {
        super.init(nibName: "Example2SwiftController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBOutlet weak var pieView: PieView2!
    var showPercent = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for year in 2009..<2014 {
            let elem = PieElement2(value: Float(5+arc4random()%8), color:randColor())
            elem.title = "\(year) year"
            pieView.pieLayer.addValues([elem], animated: false)
        }
        updatePieDisplay()
    }
    
    func updatePieDisplay() {
        if showPercent {
            pieView.pieLayer.transformTitleBlock = { (elem: PieElement!, percent: Float) -> String in
                return "\(Int(percent)) %"
            }
        } else {
            pieView.pieLayer.transformTitleBlock = { (elem: PieElement!, percent: Float) -> String in
                return (elem as! PieElement2).title ?? "Unknown"
            }
        }
    }

    func randColor() -> UIColor {
        let hue: CGFloat = ( CGFloat(arc4random() % 256) / 256.0 )
        let saturation: CGFloat = ( CGFloat(arc4random() % 128) / 256.0 ) + 0.5  //  0.5 to 1.0, away from white
        let brightness: CGFloat = ( CGFloat(arc4random() % 128) / 256.0 ) + 0.5  //  0.5 to 1.0, away from black
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    @IBAction func backPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func changePercentValuesPressed() {
        showPercent = !showPercent
        updatePieDisplay()
    }
    
    @IBAction func randomValuesPressed() {
        PieElement.animateChanges {
            for elem in self.pieView.pieLayer.values {
                elem.val = 5 + Float(arc4random()%8)
            }
        }
    }
    
    @IBAction func randomColorPressed() {
        PieElement.animateChanges {
            for elem in self.pieView.pieLayer.values {
                elem.color = self.randColor()
            }
        }
    }
}
