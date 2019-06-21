//
//  GameScene.swift
//  OnCominTrafficDeluxx
//
//  Created by Mike Morra on 2019-06-19.
//  Copyright © 2019 Mike Morra. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    override func didMove(to view: SKView) {
        spawnCar()
    }
    
    func spawnCar() {
        let car1 = SKSpriteNode(imageNamed: "car1")
        car1.position = CGPoint(x: 0,
                                 y: 1100)
        addChild(car1)
        
        let actionMove = SKAction.move(
            to: CGPoint(x: 0, y: -1100),
            duration: 2.0)
        car1.run(actionMove)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
