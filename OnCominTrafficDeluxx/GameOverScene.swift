//
//  GameOverScene.swift
//  OnCominTrafficDeluxx
//
//  Created by Erick Hobbs on 2019-07-04.
//  Copyright © 2019 Mike Morra. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    
    override func didMove(to view: SKView) {
        var background: SKSpriteNode
        background = SKSpriteNode(imageNamed: "YouLose")
        background.position =
            CGPoint(x: size.width/2, y: size.height/2)
        self.addChild(background)
       
    }
    
}
