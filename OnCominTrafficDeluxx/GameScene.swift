import SpriteKit

enum GameState : Int {
    case waitingForTap = 0
    case waitingForCrash = 1
    case playing = 2
    case gameOver = 3
}

enum PlayerState : Int {
    case idle = 0
    case boost = 1
    case crash = 2
    case dead = 3
}

struct PhysicsCategories {
    static let None: UInt32                = 0
    static let Player: UInt32              = 0b1
    static let Coin: UInt32                = 0b10
    static let Traffic: UInt32             = 0b100
    static let Powerup: UInt32             = 0b1000
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    var gameState = GameState.waitingForTap
    var playerState = PlayerState.idle
    var bgNode: SKNode!
    var fgNode: SKNode!
    var bgOverlayNode: SKNode!
    var bgOverlayHeight:CGFloat!
    var player: SKSpriteNode!
    var lastOverlayPos = CGPoint.zero
    var coin : SKSpriteNode!
    var lastOverlayHeight: CGFloat=0.0
    var levelPositionY: CGFloat=0.0
    let cameraNode = SKCameraNode()

    var lava: SKSpriteNode!
    
    ///Erick Hobbs
    var lives = 5
    var gameOver = false
    var playableRect: CGRect!
    var playableMargin: CGFloat = 0.0
    var playableHeight: CGFloat = 0.0
    var maxAspectRatio: CGFloat = 0.0
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode(rect: playableRect)
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
        print("Width: \(playableRect.width)")
        print("Height: \(playableRect.height)")
    }
    ///Erick Hobbs end

    var cops : SKSpriteNode!
    var lastUpdateTimeInterval: TimeInterval = 0
    var deltaTime: TimeInterval = 0
    var timer : CGFloat = 0.0

    override func didMove(to view: SKView) {
        maxAspectRatio = 16.0/9.0
        playableHeight = size.width / maxAspectRatio
        playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)

        let scale = SKAction.scale(to:1.0, duration: 0.5)
        let playableHeight = size.height
        let playableWidth = size.width
        playableRect = CGRect(x: 0, y: 0, width: playableWidth, height: playableHeight)
        physicsWorld.contactDelegate = self
        debugDrawPlayableArea()
        view.showsPhysics = true;
        SetupNodes()
        SetUpCoreMotion()
        setupPlayer()
        lives = 5
        fgNode.childNode(withName: "Ready")!.run(scale)
    }

    func updateLevel() {
        let cameraPos = camera!.position
        if cameraPos.y > levelPositionY - size.height {
        createBackground()
            while lastOverlayPos.y < levelPositionY {
                addRandomBackground()
            }
        }
    }
    
    func sceneCropAmount() -> CGFloat {
        guard let view = view else {
            return 0
        }
        let scale = view.bounds.size.height / size.height
        let scaledWidth = size.width * scale
        let scaledOverlap = scaledWidth - view.bounds.size.width
        return scaledOverlap / scale
    }


    func SetUpCoreMotion() -> CGFloat {
        guard let view = view else {
            return 0
        }
        let scale = view.bounds.size.height / size.height
        let scaledWidth = size.width * scale
        let scaledOverlap = scaledWidth - view.bounds.size.width
        return scaledOverlap/scale
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        if gameState == .waitingForTap {
            StartGame()
        }
    }
    
    func SetupNodes(){
        let worldNode = childNode(withName: "World")!
        bgNode = worldNode.childNode(withName: "Background")!
        bgOverlayNode = bgNode.childNode(withName: "Overlay")!.copy() as! SKNode
        bgOverlayHeight = bgOverlayNode.calculateAccumulatedFrame().height
        fgNode = worldNode.childNode(withName: "Foreground")!
        player = fgNode.childNode(withName: "Player") as! SKSpriteNode
        addChild(cameraNode)
        camera = cameraNode
        cops = fgNode.childNode(withName: "Cops") as! SKSpriteNode
        levelPositionY = bgNode.childNode(withName: "Overlay")!.position.y + bgOverlayHeight
    }
    
    func setupPlayer () {
        player.physicsBody!.isDynamic = false
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player
        player.physicsBody!.collisionBitMask = PhysicsCategories.Coin
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Coin
        player.physicsBody!.collisionBitMask = PhysicsCategories.Traffic//eh
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Traffic//eh
        setPlayerSetVelocity(750)
        player.physicsBody!.isDynamic = true
        player.physicsBody!.affectedByGravity = false
    }
    
    func updateCamera(){
        let cameraTarget = convert(player.position,from: fgNode)
        let targetPositionY = cameraTarget.y - (size.height * -0.15)
        let diff = targetPositionY - camera!.position.y
        let cameraLagFactor: CGFloat = 0.1
        let lagDiff = diff * cameraLagFactor
        let newCameraPositionY = camera!.position.y + lagDiff
        camera!.position.y = newCameraPositionY
    }
    
    func UpdateCopCollision(){
        if player.position.y < cops.position.y + 90 {
//            playerState = .dead
            setPlayerSetVelocity(750)
        }
        //checkCollisions()
    }
    
    func updateCops(_ dt: TimeInterval){
        let bottomOfScreen = camera!.position.y - (size.height / 2)
        let bottomOfScreenFG = convert(CGPoint(x: 0, y: bottomOfScreen), to: fgNode).y
        let copsVel = CGFloat(750)
        let CopsStep = copsVel * CGFloat(dt)
        var newCopsPos = cops.position.y + CopsStep
        newCopsPos = max(newCopsPos, bottomOfScreen - 125.0)
        cops.position.y = newCopsPos
    }
    
    func StartGame(){
        gameState = .playing
        let scale = SKAction.scale(to: 0, duration:  0.4)
        fgNode.childNode(withName: "Title")!.run(scale)
        fgNode.childNode(withName: "Title")!.removeFromParent()
        fgNode.childNode(withName: "Ready")!.run(
        SKAction.sequence(
            [SKAction.wait(forDuration: 0.2), scale]))

        player.physicsBody!.isDynamic = true
        player.physicsBody!.affectedByGravity = true
        setPlayerSetVelocity(250)
        
       
        ///Spawn On Coming Traffic - Erick Hobbs
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnCar()
                },
                               SKAction.wait(forDuration: 0.5)])))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnMotorbike()
                },
                               SKAction.wait(forDuration: 5.0)])))
        
    }
    ///Erick Hobbs end
    

    
    func setPlayerSetVelocity(_ amount: CGFloat){
        let gain: CGFloat = 1.5
        player.physicsBody!.velocity.dy = max(player.physicsBody!.velocity.dy, amount * gain)
    }
    func loadForegroundNode(_ fileName: String) -> SKSpriteNode {
        
        let overlayScene = SKScene(fileNamed: fileName)!
        let overlayTemplate = overlayScene.childNode(withName: "Overlay")
        return overlayTemplate as! SKSpriteNode
    }
    
    func createForeground(_ overlayTemplate: SKSpriteNode, flipX: Bool){
        
        let foregroundOverlay = overlayTemplate.copy() as! SKSpriteNode
        lastOverlayPos.y = lastOverlayPos.y + (lastOverlayHeight + (foregroundOverlay.size.height / 1))
        lastOverlayHeight = foregroundOverlay.size.height / 2
        foregroundOverlay.position = lastOverlayPos
        
        if (flipX == true)
        {
            foregroundOverlay.xScale = -1.0
        }
        fgNode.addChild(foregroundOverlay)
    }
    
    func addRandomBackground(){
        let overlaySprite = SKSpriteNode(imageNamed: "block_break01")
        let platformPercentage = 60
        lastOverlayPos.y = lastOverlayPos.y + (lastOverlayHeight + (overlaySprite.size.height / 1))
        lastOverlayHeight = overlaySprite.size.height / 2
        if Int.random(min: 1, max: 100) <= platformPercentage {

            overlaySprite.position = CGPoint(
            x: CGFloat.random(
                    min: playableRect.minX,
                    max: playableRect.maxX),
                y: player.position.y + 1000)
            
            overlaySprite.zPosition = 10
            overlaySprite.physicsBody = SKPhysicsBody(rectangleOf: overlaySprite.size)

            overlaySprite.physicsBody?.collisionBitMask = PhysicsCategories.Player
            overlaySprite.physicsBody?.categoryBitMask = PhysicsCategories.Coin
            overlaySprite.physicsBody?.contactTestBitMask = PhysicsCategories.Player
            fgNode.addChild(overlaySprite)

        } else {
//            overlaySprite = coin
        }
    }

    func createBackground() {
        let backgroundOverlay = bgOverlayNode.copy() as! SKNode
        backgroundOverlay.position = CGPoint (x:0.0, y: levelPositionY)
        bgNode.addChild(backgroundOverlay)
        levelPositionY += bgOverlayHeight
    }
    
    func didBegin(_ contact: SKPhysicsContact)  {
        let other = contact.bodyA.categoryBitMask ==
            PhysicsCategories.Player ? contact.bodyB : contact.bodyA
        switch other.categoryBitMask {
            
        case PhysicsCategories.Coin:
            if let coin = other.node as? SKSpriteNode {
                coin.removeFromParent()
                setPlayerSetVelocity(500)
            }
        case PhysicsCategories.Powerup:
            if let PU = other.node as? SKSpriteNode {
                PU.removeFromParent()
                setPlayerSetVelocity(500)
            }
            
        ///EH
        case PhysicsCategories.Traffic:
            if let traffic = other.node as? SKSpriteNode {
                traffic.removeFromParent()
                lives -= 1
            }
        ///EH end
        default:
            break
        }
    }

    ///SPAWN "ENEMYS" - Erick Hobbs
    func spawnCar() {
        let car1 = SKSpriteNode(imageNamed: "Car1")
        car1.name = "Car1"
        car1.position = CGPoint(x: CGFloat.random (
            min: cameraRect.minX + car1.size.width/2,
            max: cameraRect.maxX - car1.size.width/2),
                                y: cameraRect.maxY + car1.size.height/2)
        
        car1.size = CGSize (width: 100, height: 200)
        car1.zRotation = 3.14 * 90 / 90
        car1.zPosition = 3
        
        car1.physicsBody = SKPhysicsBody(rectangleOf: car1.size)
        car1.physicsBody?.collisionBitMask = PhysicsCategories.Player
        car1.physicsBody?.categoryBitMask = PhysicsCategories.Traffic
        car1.physicsBody?.contactTestBitMask = PhysicsCategories.Player
        car1.physicsBody!.affectedByGravity = false
        
        fgNode.addChild(car1)
        
        let actionMove =
            SKAction.moveBy(x: 0, y: -(size.height + car1.size.height), duration: 8.0)
        
        let actionRemove = SKAction.removeFromParent()
            car1.run(SKAction.sequence([actionMove, actionRemove]))
    
    }
    
    func spawnMotorbike(){
        let motorbike = SKSpriteNode(imageNamed: "Motorbike")
        motorbike.name = "Motorbike"
        motorbike.position = CGPoint(x: CGFloat.random(
            min: cameraRect.minX + motorbike.size.width/2,
            max: cameraRect.maxX - motorbike.size.width/2),
                                     y: cameraRect.maxY +
                                        motorbike.size.height/2)
        
        motorbike.size = CGSize (width: 100, height: 200)
        motorbike.zRotation = 3.14 * 90 / 90
        motorbike.zPosition = 3
        
        motorbike.physicsBody = SKPhysicsBody(rectangleOf: motorbike.size)
        motorbike.physicsBody?.collisionBitMask = PhysicsCategories.Player
        motorbike.physicsBody?.categoryBitMask = PhysicsCategories.Traffic
        motorbike.physicsBody?.contactTestBitMask = PhysicsCategories.Player
        motorbike.physicsBody!.affectedByGravity = false
        
        fgNode.addChild(motorbike)
        
        let actionMove =
            SKAction.moveBy(x: 0, y: -(size.height + motorbike.size.height), duration: 5.0)
        
        let actionRemove = SKAction.removeFromParent()
        motorbike.run(SKAction.sequence([actionMove, actionRemove]))
    }
    ///Erick Hobbs end
    
    override func update(_ currentTime: TimeInterval){

        if timer > 5 {
            addRandomBackground()
            timer = 0
        }
        
        if lastUpdateTimeInterval > 0 {
            deltaTime = currentTime  - lastUpdateTimeInterval
        }else{
            deltaTime = 0
        }
        lastUpdateTimeInterval = currentTime
        if isPaused {
            return
        }
        if gameState == .playing {
            updateCamera()
            updateLevel()
            updateCops(deltaTime)
            UpdateCopCollision()
            timer = timer + 1
        }
        ///Erick Hobbs
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You lose!")
            let gameOverScene = GameOverScene(size: size)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }

    var cameraRect : CGRect {
        let x = cameraNode.position.x - size.width/2
            + (size.width - playableRect.width)/2
        let y = cameraNode.position.y - size.height/2
            + (size.height - playableRect.height)/2
        return CGRect(
            x: x,
            y: y,
            width: playableRect.width,
            height: playableRect.height)
    }
    ///Erick Hobbs end
}



