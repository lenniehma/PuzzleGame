//
//  GameViewController.swift
//  Puzzle Game iOS
//
//  Created by Lennie Ma on 2/11/25.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {

    var gameView: SCNView {
        return self.view as! SCNView
    }
    
    var gameController: GameController!
    var playerNode: SCNNode!
    var ghostNodes: [SCNNode] = []
    
    //Currently there is a max of 3 rounds, generalize later for n rounds!
    var movementHistory: [[SCNVector3]] = [[], [], []] // Stores past movements
    
    var currentRound = 1
    var nextRoundButton: UIButton!
    var resetGameButton: UIButton!
    var adjustCameraButton: UIButton!
    var roundLabel: UILabel!
    var isCameraAdjustable = false
    var gameCompleteLabel: UILabel!
    var gameCompleteButton: UIButton!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.gameController = GameController(sceneRenderer: gameView)
        
        // Allow the user to manipulate the camera
        self.gameView.allowsCameraControl = true
        
        // Show statistics such as fps and timing information
        self.gameView.showsStatistics = true
        
        // Configure the view
        self.gameView.backgroundColor = UIColor.black
        
        resetGame()
        setupUI()
        setupScene()
        setupGestures()
    }
    
    func setupUI() {
        roundLabel = UILabel(frame: CGRect(x: self.view.frame.width / 2 - 50, y: 40, width: 100, height: 30))
        roundLabel.textAlignment = .center
        roundLabel.textColor = .white
        roundLabel.font = UIFont.boldSystemFont(ofSize: 20)
        roundLabel.text = "Round 1"
        if let label = roundLabel {
            self.view.addSubview(label)
        }
        
        adjustCameraButton = UIButton(frame: CGRect(x: 10, y: self.view.frame.height - 80, width: 150, height: 50))
        adjustCameraButton.setTitle("Adjust Camera", for: .normal)
        adjustCameraButton.backgroundColor = .gray
        adjustCameraButton.addTarget(self, action: #selector(toggleCameraAdjustable), for: .touchUpInside)
        self.view.addSubview(adjustCameraButton)
        
        nextRoundButton = UIButton(frame: CGRect(x: 170, y: self.view.frame.height - 80, width: 150, height: 50))
        nextRoundButton.setTitle("Next Round", for: .normal)
        nextRoundButton.backgroundColor = .blue
        nextRoundButton.addTarget(self, action: #selector(nextRound), for: .touchUpInside)
        self.view.addSubview(nextRoundButton)
        
        resetGameButton = UIButton(frame: CGRect(x: 330, y: self.view.frame.height - 80, width: 150, height: 50))
        resetGameButton.setTitle("Reset Game", for: .normal)
        resetGameButton.backgroundColor = .red
        resetGameButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        self.view.addSubview(resetGameButton)
    }
    
    func showGameCompleteScreen() {
        //print(movementHistory)
        gameCompleteLabel = UILabel(frame: CGRect(x: self.view.frame.width / 2 - 100, y: self.view.frame.height / 2 - 50, width: 200, height: 50))
        gameCompleteLabel.textAlignment = .center
        gameCompleteLabel.textColor = .white
        gameCompleteLabel.font = UIFont.boldSystemFont(ofSize: 24)
        gameCompleteLabel.text = "Game Complete!"
        self.view.addSubview(gameCompleteLabel)
        
        gameCompleteButton = UIButton(frame: CGRect(x: self.view.frame.width / 2 - 75, y: self.view.frame.height / 2, width: 150, height: 50))
        gameCompleteButton.setTitle("Restart Game?", for: .normal)
        gameCompleteButton.backgroundColor = .green
        gameCompleteButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        self.view.addSubview(gameCompleteButton)
    }
    
    @objc func toggleCameraAdjustable() {
      isCameraAdjustable.toggle()
      gameView.allowsCameraControl = isCameraAdjustable
      adjustCameraButton.backgroundColor = isCameraAdjustable ? .green : .gray
    }
    
    func updateRoundLabel() {
        if roundLabel != nil {
            roundLabel.text = "Round \(currentRound)"
        }
    }
    
    
    @objc func resetGame() {
        print("Resetting game...")

        // Clear previous data
        currentRound = 1
        movementHistory = [[], [], []]

        // Remove old nodes from the scene
        gameView.scene?.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        // Reset Player
        playerNode?.removeAllActions()
        playerNode?.position = SCNVector3(0, 0, 0)

        // Clear ghost nodes
        ghostNodes.removeAll()
        
        // Hide game complete UI if it exists
        gameCompleteLabel?.removeFromSuperview()
        gameCompleteButton?.removeFromSuperview()
        
        //Reinitialize the scene
        setupScene()
        updateRoundLabel()
    }
    
    func setupScene() {
        let scene = SCNScene()
        gameView.scene = scene
        gameView.debugOptions = [.showWireframe, .showPhysicsShapes]
        
        //Setup Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 10, 10)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        // Setup Player
        playerNode = SCNNode(geometry: SCNSphere(radius: 0.5))
        playerNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        playerNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(playerNode)
        
        // Setup Ground
        let groundNode = SCNNode(geometry: SCNPlane(width: 10, height: 10))
        groundNode.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
        groundNode.eulerAngles.x = -.pi / 2
        scene.rootNode.addChildNode(groundNode)
    }
    
    func setupGestures() {
        // Swipe Up for Forward Movement
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(moveForward))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        // Swipe Down for Backward Movement
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(moveBackward))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        // Swipe Left for Left Movement
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(moveLeft))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        // Swipe Right for Right Movement
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(moveRight))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    @objc func moveForward() {
        movePlayer(by: SCNVector3(0, 0, -1))
    }
    
    @objc func moveBackward() {
        movePlayer(by: SCNVector3(0, 0, 1))
    }
    
    @objc func moveLeft() {
        movePlayer(by: SCNVector3(-1, 0, 0))
    }
    
    @objc func moveRight() {
        movePlayer(by: SCNVector3(1, 0, 0))
    }
    
    func movePlayer(by vector: SCNVector3) {
        let moveAction = SCNAction.move(by: vector, duration: 0.5)
        playerNode.runAction(moveAction)
        
        // Record Movement
        if currentRound - 1 < movementHistory.count {
            movementHistory[currentRound - 1].append(playerNode.position)
        } else {
            print("Error: currentRound index \(currentRound) out of bounds for movementHistory")
        }
    }

    @objc func nextRound() {
        if currentRound < 3 { // Allow 3 rounds
            print("Starting round \(currentRound + 1)")
            
            let newGhost = SCNNode(geometry: SCNSphere(radius: 0.5))
            newGhost.geometry?.firstMaterial?.diffuse.contents = currentRound == 2 ? UIColor.blue : UIColor.yellow
            newGhost.position = SCNVector3(0, 0, 0) // Start at origin
            gameView.scene?.rootNode.addChildNode(newGhost)
            ghostNodes.append(newGhost)
            
            // Reset playerNode for the new round
            playerNode.position = SCNVector3(0, 0, 0)
            playerNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            
            // Update round counter and label
            currentRound += 1
            updateRoundLabel()
            
            if currentRound >= 2 {
                // Replay all ghosts (asynchronous)
                DispatchQueue.main.async {
                    for (index, ghost) in self.ghostNodes.enumerated() {
                        self.replayGhost(for: index, ghost: ghost)
                    }
                }
            }
            
        } else {
            showGameCompleteScreen()
        }
    }
    
    func replayGhost(for round: Int, ghost: SCNNode) {
        let pastMovements = movementHistory[round]
        var actions: [SCNAction] = []
        for move in pastMovements {
            let moveAction = SCNAction.move(to: move, duration: 0.5)
            actions.append(moveAction)
        }
        
        // Run ghost replay without blocking the main thread
        DispatchQueue.global(qos: .userInteractive).async {
            ghost.runAction(SCNAction.sequence(actions), completionHandler: {
                print("Ghost for round \(round) finished replaying")
            })
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}
