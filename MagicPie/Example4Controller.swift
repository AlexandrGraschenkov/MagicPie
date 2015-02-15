//
//  Example4Controller.swift
//  MagicPie
//
//  Created by Alexander on 15.02.15.
//  Copyright (c) 2015 Alexandr Corporation. All rights reserved.
//

import UIKit
import Foundation

@objc class Example4Controller: UIViewController {
    
    @IBOutlet weak private var pie: Example4PieView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        println(pie)
    }
    
    @IBAction func backPressed() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func start() {
        pie.startWaveAnimation()
    }
    
    @IBAction func end() {
        pie.stopWaveAnimation()
    }
}


class Example4PieView : UIView {
    
    override class func layerClass() -> AnyClass {
        return PieLayer.self
    }
    
    private var pieLayer: PieLayer {
        return layer as PieLayer
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    private func commonInit() {
        let elems = (0...200).map({ _ in PieElement(value: 1.0, color: self.waveColor) })
        pieLayer.addValues(elems, animated: false)
        pieLayer.maxRadius = 150
        pieLayer.minRadius = 20
    }
    
    var waveColor = UIColor.lightGrayColor()
    private var phase: Float = 0
    private var timer: NSTimer?
    
    func updatePhaseAnimated() {
        updatePhaseAnimated(0.05)
    }
    private func updatePhaseAnimated(duration: Float) {
        phase += 0.1
        if phase > 1 { phase -= 1 }
        let waveLengthElemCount = 10
        pieLayer.animationDuration = duration
        pieLayer.deleteValues([pieLayer.values[0], pieLayer.values[1]], animated: true)
        PieElement.animateChanges {
            
            if self.animationRunning {
                let count = self.pieLayer.values.count
                for i in 0..<(count / 2) {
                    var val = Float(i) / Float(waveLengthElemCount) + self.phase
                    while val > 1.0 {
                        val -= 1.0
                    }
                    let elem1 = self.pieLayer.values[i] as PieElement
                    let brigtness = CGFloat(sin(val * 2 * Float(M_PI))) * 0.25 + 0.5
                    var color1 = UIColor(hue: (CGFloat(i) / CGFloat(count)), saturation: 0.5, brightness: brigtness, alpha: 1.0)
                    elem1.color = color1
                    
                    let i2 = count - i - 1
                    let elem2 = self.pieLayer.values[i2] as PieElement
                    var color2 = UIColor(hue: (CGFloat(i2) / CGFloat(count)), saturation: 0.8, brightness: brigtness, alpha: 1.0)
                    elem2.color = color2
                }
            } else {
                for elem in self.pieLayer.values as [PieElement] {
                    elem.color = self.waveColor
                }
            }
        }
    }
    
    private func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    private var cancelAnimation: (()->())?
    private var animationRunning: Bool {
        return cancelAnimation != nil
    }
    func startWaveAnimation() {
        if animationRunning { return }
        
        var canceled = false
        cancelAnimation = {
            canceled = true
            self.timer?.invalidate()
            self.timer = nil
        }
        
        updatePhaseAnimated(0.3)
        delay(0.3) {
            if canceled { return }
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "updatePhaseAnimated", userInfo: nil, repeats: true)
        }
    }
    
    func stopWaveAnimation() {
        cancelAnimation?()
        cancelAnimation = nil
        updatePhaseAnimated(0.4)
    }
    
    private func colorBrightness(color: UIColor, brightness: Float) -> UIColor {
        var hue: CGFloat = 0, sat: CGFloat = 0, brig: CGFloat = 0, a: CGFloat = 0
        color.getHue(&hue, saturation: &sat, brightness: &brig, alpha: &a)
        let brigMult = max(min(1, brightness), -1) * 0.5 + 1.0
        brig *= CGFloat(brigMult)
        return UIColor(hue: hue, saturation: sat, brightness: brig, alpha: a)
    }
}
