//
//  SpriteShatter.swift
//  SpriteShatter
//
//  Created by Matthew Reagan on 7/28/18.
//  Copyright © 2018 Matt Reagan. All rights reserved.
//

import SpriteKit

class ShatterPieceNode: SKCropNode {
    var shatterAnimationMetadata: ShatterPieceAnimation?
}

class ShatterNode: SKNode {
    var pieces: [ShatterPieceNode] = []
}

enum ShatterAnimationType {
    case automatic
    case manual
}

extension SKSpriteNode {
    
    /// Shatter function. When called on an SKSpriteNode, it creates a grid of child nodes to represent
    /// pieces of the original, which are then animated to create a 'shattering' effect. The original node
    /// is hidden and can be removed by the caller if needed.
    ///
    /// - Parameters:
    ///   - gridResolution: Size of the shatter. Each X,Y results in the creation of 2 triangle nodes, which
    ///                     in turn have parent SKCropNodes and related masking nodes.
    ///   - animation: The animation style. This is mostly for demo purposes, 'automatic' is almost always desirable.
    ///   - showHeatmap: Added for demo app colorization. Can be removed.
    /// - Returns: Returns a reference to the newly-created parent node which owns all of the children for the shatter.
    
    @discardableResult func shatter(into gridResolution: CGSize, animation: ShatterAnimationType, showHeatmap: Bool) -> ShatterNode {
        guard let originalTexture = texture else { fatalError("\(#function) requires a node with a valid SKTexture.") }
        
        let originalTextureRect = originalTexture.textureRect()
        let originalSize = size
        let gridSizeWidth = gridResolution.width.rounded()
        let gridSizeHeight = gridResolution.height.rounded()
        
        // Hide the receiver
        
        isHidden = true
        
        
        // Create the root parent node which will hold all of the shattered 'pieces'
        
        let shatterParentNode = ShatterNode()
        shatterParentNode.position = position
        shatterParentNode.zPosition = zPosition
        shatterParentNode.zRotation = zRotation
        parent?.addChild(shatterParentNode)
        
        let pieceWidth: CGFloat = originalSize.width / gridSizeWidth
        let pieceHeight: CGFloat = originalSize.height / gridSizeHeight
        let halfPieceWidth = pieceWidth / 2.0
        let halfPieceHeight = pieceHeight / 2.0
        
        var pieces: [ShatterPieceNode] = []
        
        let triangleCropShapes: [SKShapeNode] = {
            
            func trianglePath(for index: Int) -> CGPath {
                let path = CGMutablePath()
                switch index {
                case 0:
                    path.move(to: CGPoint(x: -halfPieceWidth, y: -halfPieceHeight))
                    path.addLine(to: CGPoint(x: -halfPieceWidth, y: halfPieceHeight))
                    path.addLine(to: CGPoint(x: halfPieceWidth, y: halfPieceHeight))
                case 1:
                    path.move(to: CGPoint(x: halfPieceWidth, y: halfPieceHeight))
                    path.addLine(to: CGPoint(x: halfPieceWidth, y: -halfPieceHeight))
                    path.addLine(to: CGPoint(x: -halfPieceWidth, y: -halfPieceHeight))
                default:
                    fatalError("Invalid triangle index, expecting range of 0...1.")
                }
                path.closeSubpath()
                return path
            }
            
            func triangleCropShape(for index: Int) -> SKShapeNode {
                let cropShape = SKShapeNode.init(path: trianglePath(for: index))
                cropShape.lineWidth = 0.0
                cropShape.isAntialiased = false
                cropShape.fillColor = SKColor.black
                return cropShape
            }
            
            return [triangleCropShape(for: 0), triangleCropShape(for: 1)]
        }()
        
        // This only needs to be calculated once, for 0,0. Each corner is equidistant from the center
        // and the corner pieces will be the furthest away from the 'blast point'
        let calculatedMaxPieceDistance: CGFloat = CGPoint(x: -(originalSize.width / 2.0) + halfPieceWidth, y: -(originalSize.height / 2.0)  + halfPieceHeight).distance(to: .zero)
        
        for y in 0..<Int(gridSizeHeight) {
            for x in 0..<Int(gridSizeWidth) {
                for triangleIndex in 0...1 {
                    
                    // Calculate the subtexture coordinates and starting position for the individual shatter piece node
                    
                    let subtextRect = CGRect(x: CGFloat(x) / gridSizeWidth * originalTextureRect.size.width + originalTextureRect.origin.x,
                                             y: CGFloat(y) / gridSizeHeight * originalTextureRect.size.height + originalTextureRect.origin.y,
                                             width: originalTextureRect.size.width / gridSizeWidth,
                                             height: originalTextureRect.size.height / gridSizeHeight)
                    let subtexture = SKTexture.init(rect: subtextRect, in: originalTexture)
                    let newX = CGFloat(CGFloat(x) * pieceWidth - (originalSize.width / 2.0) + halfPieceWidth)
                    let newY = CGFloat(CGFloat(y) * pieceHeight  - (originalSize.height / 2.0)  + halfPieceHeight)
                    
                    // Create the crop node, its mask, and the actual textured sprite
                    
                    let piece = SKSpriteNode.init(texture: subtexture)
                    piece.size = CGSize(width: pieceWidth, height: pieceHeight)
                    let shatterPieceNode = ShatterPieceNode()
                    guard let maskNode = triangleCropShapes[triangleIndex].copy() as? SKShapeNode else { fatalError("Could not obtain copy of SKShapeNode for crop mask.") }
                    shatterPieceNode.maskNode = maskNode
                    shatterPieceNode.position = CGPoint(x: newX, y: newY)
                    shatterPieceNode.addChild(piece)
                    shatterParentNode.addChild(shatterPieceNode)
                    
                    //////////////////////////////////////////////////////////////////////
                    // Here is where the individual pieces are randomized and animated
                    // Tweaking these values will allow control over the spin, scaling,
                    // and movement of each piece in the shatter effect
                    
                    let blastIntensity = 1.0 - (CGPoint(x: newX, y: newY).distance(to: .zero) / calculatedMaxPieceDistance)
                    let angleFromCenter: CGFloat = atan2(newY, newX)
                    let distance: CGFloat = 100.0 + (100.0 * Random.between0And1())
                    let speed: CGFloat = 0.3 + (0.6 * blastIntensity) + (1.5 * Random.between0And1()) + (arc4random() % 6 == 0 ? 4.0 : 0.0) /* Make a few pieces really fly out */
                    let rotationSpin = (angleFromCenter * 24.0 * Random.between0And1()) * (triangleIndex == 1 ? 1 : -1)
                    let scaleAdjust = (Random.between0And1() * 2.0) - 1.0
                    
                    //////////////////////////////////////////////////////////////////////
                    
                    // Colorization (for demo)
                    
                    if showHeatmap {
                        piece.color = SKColor(calibratedRed: blastIntensity,
                                              green: 1.0 - blastIntensity,
                                              blue: 1.0 - blastIntensity, alpha: 1.0)
                        piece.colorBlendFactor = 1.0
                    }
                    
                    // Animate each node. The 'manual' animation mode is mostly for demo app purposes
                    
                    switch animation {
                    case .manual:
                        let animationMetadata = ShatterPieceAnimation(startPosition: CGPoint(x: newX, y: newY),
                                                                      distance: distance,
                                                                      angle: angleFromCenter,
                                                                      speed: speed,
                                                                      scale: scaleAdjust,
                                                                      rotation: rotationSpin)
                        shatterPieceNode.shatterAnimationMetadata = animationMetadata
                        
                    case .automatic:
                        let newPoint = CGPoint(x: (cos(angleFromCenter) * distance) + newX,
                                               y: (sin(angleFromCenter) * distance) + newY)
                        let animationDuration = TimeInterval(2.0)
                        shatterPieceNode.run(.group([
                            SKAction.move(to: newPoint, duration: animationDuration),
                            SKAction.rotate(byAngle: rotationSpin, duration: animationDuration),
                            .sequence([.wait(forDuration: animationDuration * 0.75),
                                       SKAction.fadeAlpha(to: 0.0, duration: animationDuration * 0.25),
                                       SKAction.removeFromParent()])
                            ]))
                    }
                    
                    // Convenience: keep track of the piece nodes in a discrete collection on the parent
                    
                    pieces.append(shatterPieceNode)
                }
            }
        }
        
        shatterParentNode.pieces = pieces
        return shatterParentNode
    }
    
    /// Shorthand for longer shatter function
    
    @discardableResult func shatter() -> ShatterNode {
        return shatter(into: CGSize(width: 8, height: 16), animation: .automatic, showHeatmap: false) // A sensisble default size can be passed here for convenience
    }
}

/// Data structure for capturing the individual animation properties for
/// a given 'shatter piece'. This is mostly for the demo app, and typically an animation
/// mode of 'automatic' will be used which simply animates each piece with SKAction.

struct ShatterPieceAnimation {
    let startPosition: CGPoint
    let distance: CGFloat
    let angle: CGFloat
    let speed: CGFloat
    let scale: CGFloat
    let rotation: CGFloat
    
    func applyPositionAndRotation(for animationProgress: CGFloat,
                                  to node: ShatterPieceNode) {
        assert(animationProgress >= 0.0 && animationProgress <= 1.0, "Invalid progress range.")
        
        let effectiveProgress = min(animationProgress * (2.0 * speed), 1.0)
        
        let minY: CGFloat = -160.0 // Provide a minimum Y as a 'floor' for the demo app
        let newY = startPosition.y + (sin(angle) * distance * effectiveProgress)
        let position = CGPoint(x: startPosition.x + (cos(angle) * distance * effectiveProgress),
                               y: newY < minY ? minY + ((newY - minY) * -0.50) : newY)
        let newScale = 1.0 + (animationProgress * scale)
        
        node.position = position
        node.zRotation = rotation * animationProgress
        node.xScale = newScale
        node.yScale = newScale
        
        node.maskNode!.alpha = 1.0 - (max(effectiveProgress - 0.9, 0.0) / 0.1)
    }
}

/// Conveniences for SKAction timing modes

extension SKAction {
    func byEasingIn() -> SKAction {
        self.timingMode = .easeIn
        return self
    }
    func byEasingInOut() -> SKAction {
        self.timingMode = .easeInEaseOut
        return self
    }
    func byEasingOut() -> SKAction {
        self.timingMode = .easeOut
        return self
    }
}

/// Provides some simple conveniences for obtaining pseudorandom values

struct Random {
    static func seed() {
        srand48(Int(time(nil)))
    }
    static func between0And1() -> CGFloat {
        return CGFloat(drand48())
    }
}

/// Conveniences for CGPoint

extension CGPoint {
    func distance(to otherPoint: CGPoint) -> CGFloat {
        let xDelta = x - otherPoint.x
        let yDelta = y - otherPoint.y
        return ((xDelta * xDelta) + (yDelta * yDelta)).squareRoot()
    }
}
