//
//  ViewController.swift
//  SpriteShatter
//
//  Created by Matthew Reagan on 7/28/18.
//  Copyright © 2018 Matt Reagan. All rights reserved.
//

import Cocoa
import SpriteKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    @IBOutlet weak var animationSlider: NSSlider!
    @IBOutlet weak var resolutionXTextField: NSTextField!
    @IBOutlet weak var resolutionYTextField: NSTextField!
    @IBOutlet weak var heatmapCheckbox: NSButton!
    
    let bottle = SKSpriteNode(imageNamed: "bottle")
    var shatterNode: ShatterNode?
    var animationTimer: Timer?
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViewAndScene()
        resetAndPlayDemoAnimation()
    }

    // MARK: - UI Actions
    
    @IBAction func updateClicked(_ sender: Any) {
        resetAndPlayDemoAnimation()
    }
    
    @IBAction func sliderChanged(_ sender: Any) {
        animationTimer?.invalidate()
        updateAnimation()
    }
    
    @IBAction func heatmapCheckboxClicked(_ sender: Any) {
        resetAndPlayDemoAnimation()
    }
    
    // MARK: - Demo App Utilities
    
    func updateAnimation() {
        let progress = CGFloat(animationSlider.doubleValue)
        if let shatterPieces = shatterNode?.pieces {
            for piece in shatterPieces {
                if let animationMetadata = piece.shatterAnimationMetadata {
                    animationMetadata.applyPositionAndRotation(for: progress, to: piece)
                }
            }
        }
    }
    
    func resetAndPlayDemoAnimation() {
        shatterNode?.removeFromParent()
        shatterNode = nil
        animationTimer?.invalidate()
        animationSlider.doubleValue = 0.0
        let resolutionX = max(min(resolutionXTextField.integerValue, 24), 2)
        let resolutionY = max(min(resolutionYTextField.integerValue, 24), 2)
        shatterNode = bottle.shatter(into: CGSize(width: resolutionX, height: resolutionY), animation: .manual, showHeatmap: heatmapCheckbox.state == .on)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [weak self] in
            self?.runDemoAnimation()
        })
    }
    
    func runDemoAnimation() {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true, block: { [weak self] timer in
            if let blockSelf = self {
                if blockSelf.animationSlider.doubleValue < 1.0 {
                    blockSelf.animationSlider.doubleValue += 0.008
                    blockSelf.updateAnimation()
                } else {
                    timer.invalidate()
                }
            }
        })
    }
    
    func setUpViewAndScene() {
        if let view = self.skView {
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
            
            let size = view.bounds.size
            let scene = SKScene.init(size: size)
            scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            scene.scaleMode = .aspectFill
            scene.backgroundColor = SKColor.black
            view.presentScene(scene)

            // For a fun effect, un-comment this:
            /*
            let filter = CIFilter.init(name: "CIEdges")!
            filter.setDefaults()
            filter.setValue(25.0, forKey: "inputIntensity")
            scene.filter = filter
            scene.shouldEnableEffects = true
            */
            
            let attributes = [NSAttributedStringKey.foregroundColor: NSColor.white]
            let titleString = NSAttributedString(string: "Heatmap", attributes: attributes)
            heatmapCheckbox.attributedTitle = titleString
            
            let background = SKSpriteNode(imageNamed: "background")
            background.size = size
            background.zPosition = -10.0
            scene.addChild(background)
            
            scene.addChild(bottle)
            bottle.position = CGPoint(x: 0.0, y: -50.0)
            Random.seed()
        }
    }
}

