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
        
        let wait = SKAction.wait(forDuration: 3.0)
        let block = SKAction.run {
            let myScene = GameScene(fileNamed: "GameScene")
            myScene!.scaleMode = self.scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(myScene!, transition: reveal)
        }
        self.run(SKAction.sequence([wait, block]))
       
    }
    
}
