//
//  GameViewController.swift
//  swifty-protein
//
//  Created by Antoine JOUANNAIS on 5/26/17.
//  Copyright © 2017 Antoine JOUANNAIS. All rights reserved.
//

import UIKit
import SceneKit
import Foundation

// extension pour se simplifier la lecture d'une sous-chaine
extension String {

    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.characters.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.characters.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return self[startIndex ..< endIndex]
    }
}

// vu sur https://stackoverflow.com/questions/30190171/scenekit-object-between-two-points/38043369#38043369

class   CylinderLine: SCNNode
{
    init( parent: SCNNode,//Needed to line to your scene
        v1: SCNVector3,//Source
        v2: SCNVector3,//Destination
        radius: CGFloat,// Radius of the cylinder
        radSegmentCount: Int, // Number of faces of the cylinder
        color: UIColor )// Color of the cylinder
    {
        super.init()
        
        //Calcul the height of our line
        let  height = v1.distance(receiver: v2)
        
        //set position to v1 coordonate
        position = v1
        
        //Create the second node to draw direction vector
        let nodeV2 = SCNNode()
        
        //define his position
        nodeV2.position = v2
        //add it to parent
        parent.addChildNode(nodeV2)
        
        //Align Z axis
        let zAlign = SCNNode()
        zAlign.eulerAngles.x = Float(CGFloat(M_PI_2))
        
        //create our cylinder
        let cyl = SCNCylinder(radius: radius, height: CGFloat(height))
        cyl.radialSegmentCount = radSegmentCount
        cyl.firstMaterial?.diffuse.contents = color
        
        //Create node with cylinder
        let nodeCyl = SCNNode(geometry: cyl )
        nodeCyl.position.y = -height/2
        zAlign.addChildNode(nodeCyl)
        
        //Add it to child
        addChildNode(zAlign)
        
        //set constraint direction to our vector
        constraints = [SCNLookAtConstraint(target: nodeV2)]
    }
    
    override init() {
        super.init()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

private extension SCNVector3{
    func distance(receiver:SCNVector3) -> Float{
        let xd = receiver.x - self.x
        let yd = receiver.y - self.y
        let zd = receiver.z - self.z
        let distance = Float(sqrt(xd * xd + yd * yd + zd * zd))
        
        if (distance < 0){
            return (distance * -1)
        } else {
            return (distance)
        }
    }
}

class Atom : NSObject {
/*
     Record Format
     
     COLUMNS        DATA  TYPE    FIELD        DEFINITION
     -------------------------------------------------------------------------------------
     1 -  6        Record name   "ATOM  "
     7 - 11        Integer       serial       Atom  serial number.
     13 - 16        Atom          name         Atom name.
     17             Character     altLoc       Alternate location indicator.
     18 - 20        Residue name  resName      Residue name.
     22             Character     chainID      Chain identifier.
     23 - 26        Integer       resSeq       Residue sequence number.
     27             AChar         iCode        Code for insertion of residues.
     31 - 38        Real(8.3)     x            Orthogonal coordinates for X in Angstroms.
     39 - 46        Real(8.3)     y            Orthogonal coordinates for Y in Angstroms.
     47 - 54        Real(8.3)     z            Orthogonal coordinates for Z in Angstroms.
     55 - 60        Real(6.2)     occupancy    Occupancy.
     61 - 66        Real(6.2)     tempFactor   Temperature  factor.
     77 - 78        LString(2)    element      Element symbol, right-justified.
     79 - 80        LString(2)    charge       Charge  on the atom.
*/
    var serial : Int
    var name : String
    var chainID : Character
    var x : Float
    var y : Float
    var z : Float
    var element : String
    var color : UIColor
    
    var linkedAtoms : [Int] = []
    init(record : String) {
        // on recupere un "record" complet et on le transforme en objet
        print("init : record = \(record)")
        self.serial = Int(record.substring(from: 6, to: 10).trimmingCharacters(in: .whitespaces))!
        self.name = record.substring(from: 12, to: 15)
        self.chainID = record[21]
        self.x = Float(record.substring(from: 30, to: 37).trimmingCharacters(in: .whitespaces))!
        self.y = Float(record.substring(from: 38, to: 45).trimmingCharacters(in: .whitespaces))!
        self.z = Float(record.substring(from: 46, to: 53).trimmingCharacters(in: .whitespaces))!
        self.element = record.substring(from: 76, to: 77)
        // couleurs definies ici : https://en.wikipedia.org/wiki/CPK_coloring
        switch element {
        case " H":
            color = UIColor.white
        case " C":
            color = UIColor.black
        case " N":
            color = UIColor(red: 0, green: 0, blue: 0xFF, alpha:1) // dark blue
        case " O":
            color = UIColor.red
        case " F", "Cl":
            color = UIColor.green
        case "Br":
            color = UIColor(red: 0x99, green: 0, blue: 0, alpha:1) // dark red
        case " I":
            color = UIColor(red: 0x33, green: 0x00, blue: 0x99, alpha:1) // dark violet
        case "He", "Ne","Ar","Xe", "Kr":
            color = UIColor.cyan
        case " P":
            color = UIColor.orange
        case " S":
            color = UIColor.yellow
        case " B":
            color = UIColor(red: 0xFF, green: 0x99, blue: 0x66, alpha:1) // peach
        case "Li", "Na"," K", "Rb", "Cs", "Fr":
            color = UIColor.purple
        case "Be", "Mg", "Ca", "Sr", "Ba", "Ra":
            color = UIColor(red: 0x00, green: 0x66, blue: 0x00, alpha:1) // dark green
        case "Ti":
            color = UIColor.gray
        case "Fe":
            color = UIColor(red: 0xFF, green: 0x66, blue: 0x00, alpha:1) // dark orange
        default:
            color = UIColor(red: 0xFF, green: 0x33, blue: 0xFF, alpha:1) // pink
        }
    }
    
    func addLink(_ atomSerial : Int) {
        self.linkedAtoms.append(atomSerial)
    }
    
    override var description : String {
        var str = "serial: \(serial), name: \(name), x: \(x), y: \(y), z: \(z), element: \(element), links: "
        for link in self.linkedAtoms {
            str += "\(link) "
        }
        return str
    }
}

class GameViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var ligand: String = ""
    var atoms : [Int: Atom] = [:]
    
    @IBOutlet weak var msg: UILabel! // pour afficher le nom du ligand ou de l'atome
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func addLinks(conect:String) {
        /*
         The CONECT records specify connectivity between atoms for which coordinates are supplied.
         The connectivity is described using the atom serial number as shown in the entry. 
         CONECT records are mandatory for HET groups (excluding water) and for other bonds not specified in the standard residue connectivity table. 
         These records are generated automatically.
         
         Record Format
         
         COLUMNS       DATA  TYPE      FIELD        DEFINITION
         -------------------------------------------------------------------------
         1 -  6        Record name    "CONECT"
         7 - 11       Integer        serial       Atom  serial number
         12 - 16        Integer        serial       Serial number of bonded atom
         17 - 21        Integer        serial       Serial  number of bonded atom
         22 - 26        Integer        serial       Serial number of bonded atom
         27 - 31        Integer        serial       Serial number of bonded atom
         */
        let atomSerial = Int(conect.substring(from: 6, to: 10).trimmingCharacters(in: .whitespaces))!
        let firstBondedAtom = Int(conect.substring(from: 11, to: 15).trimmingCharacters(in: .whitespaces))!
        if let atom = atoms[atomSerial] {
            atom.addLink(firstBondedAtom)
            if let secondBondedAtom = Int(conect.substring(from: 16, to: 20).trimmingCharacters(in: .whitespaces)) {
                atoms[atomSerial]?.addLink(secondBondedAtom)
            }
            if let thirdBondedAtom = Int(conect.substring(from: 21, to: 25).trimmingCharacters(in: .whitespaces)) {
                atom.addLink(thirdBondedAtom)
            }
            if let fourthBondedAtom = Int(conect.substring(from: 26, to: 30).trimmingCharacters(in: .whitespaces)) {
                atom.addLink(fourthBondedAtom)
            }
        }
        else {
            print("Bizarre, j'ai trouvé un lien pour un atom inconnu... Il est donc ignoré")
        }
    }

    // initialisation de la reconnaissance d'un clic sur un objet graphique pour afficher son nom
    func initTapGestures() {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTapsRequired = 2
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.addTarget(self, action: #selector(sceneTapped(recognizer:)))
        
        var gestureRecognizers = [tapRecognizer as UIGestureRecognizer]
        if let arr = scnView.gestureRecognizers { // il existe deja des gestes
            gestureRecognizers = arr + gestureRecognizers // je mets mon geste en dernier (sinon il n'est pa reconnu)
        }
        scnView.gestureRecognizers = gestureRecognizers
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        msg.text = "Ligand : " + ligand
        setupView()
        setupScene()
        getLigand()
        initTapGestures()
       }
   
    func sceneTapped(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: scnView)
        print("sceneTapped : location = \(location)")
        let hitResults = scnView.hitTest(location, options: nil)
        if hitResults.count > 0 {
            let result = hitResults[0] 
            let node = result.node
            if let name = node.name {
                msg.text = NSLocalizedString("Atom : ", comment:"Atom") + name
            }
        }
    }
    
    func processLigandFile(_ data : String) {
        print(data)
        let records : [String] = data.components(separatedBy: "\n")
        // je recupere tous les records de type ATOM
        var searchString = "ATOM"
        let atomRecords = records.filter({ (record) -> Bool in
            let recordText: String = record
            return (recordText.range(of: searchString) != nil)
        })
        
        // on remet la liste a zero
        self.atoms = [:]
        // on charge la liste des atomes
        for atom in atomRecords {
            print("atom : \(atom)")
            let index = Int(atom.substring(from: 6, to: 10).trimmingCharacters(in: .whitespaces))!
            self.atoms[index] = Atom(record: atom)
        }
        // je recupere tous les records de type CONECT
        searchString = "CONECT"
        let conectRecords = records.filter({ (record) -> Bool in
            let recordText: String = record
            return (recordText.range(of: searchString) != nil)
        })
        for conect in conectRecords {
            print("conect : \(conect)")
            self.addLinks(conect: conect)
        }
        
        // debug
        for atom in self.atoms {
            print(atom)
        }
    }
   
    func getLigand() {
        print("getLigang \(self.ligand)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let urlString = "https://files.rcsb.org/ligands/view/\(self.ligand)_model.pdb"
        guard let requestUrl = URL(string:urlString) else {
            print("url is incorrect : \(urlString)")
            return
        }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let err = error {
                // DispatchQueue.main.async
                let errMsg = NSLocalizedString("Network error", comment: "An error message")
                print("\(errMsg) : \(err)")
                let alert = UIAlertController(title: "Error", message: errMsg, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Ok", style: .destructive, handler: nil)
                alert.addAction(alertAction)
                
                self.present(alert, animated: true, completion: nil)
            }
            else if let usableData = data {
                let returnData = String(data: usableData, encoding: .utf8)
                if let resp = response as? HTTPURLResponse {
                    print("Status code de la reponse : \(resp.statusCode)")
                }
                self.processLigandFile(returnData!)
                self.displayLigands()
            }
        }
        task.resume()
    }
    
    // je veux garder la status bar pour pouvoir afficher la roue d'activité réseau
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    func setupView() {
        // scnView = self.view as! SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
    }

    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
    }
    
    func setupCamera(_ position : SCNVector3) {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = position
        scnScene.rootNode.addChildNode(cameraNode)

    }
    
    func displayLigands() {
        print("displayLigands")
        var cameraOn = false

        // dessiner les differents atoms
        for (_, atom) in self.atoms {
            if cameraOn == false {
                cameraOn = true
                let camPos = SCNVector3(atom.x, atom.y, 15 + atom.z)
                setupCamera(camPos)
            }
            drawAtom(atom)
        }
    }
    
    func drawAtom(_ atom : Atom) {
        let sphere = SCNSphere(radius: CGFloat(0.5))
        sphere.materials.first?.diffuse.contents = atom.color
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = atom.element // le nom de l'atome est stocke ici
        scnScene.rootNode.addChildNode(sphereNode)
        sphereNode.position = SCNVector3(atom.x, atom.y, atom.z)
        for linked in atom.linkedAtoms {
            if let b = self.atoms[linked] {
                let stick = CylinderLine(
                    parent: scnScene.rootNode,
                    v1: SCNVector3(atom.x, atom.y, atom.z),
                    v2:SCNVector3(b.x, b.y, b.z),
                    radius: 0.1,
                    radSegmentCount: 10,
                    color:UIColor.white)
                stick.name = NSLocalizedString("link", comment: "Name of link")
                scnScene.rootNode.addChildNode(stick)
            }
        }
    }
}
