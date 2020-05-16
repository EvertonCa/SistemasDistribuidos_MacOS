//
//  ViewController.swift
//  SistemasDistribuidos
//
//  Created by Everton Cardoso on 14/05/20.
//  Copyright © 2020 Everton Cardoso. All rights reserved.
//

import Cocoa
import MultipeerConnectivity

enum SelectedMode: Int {
    case Solo = 0
    case Host = 1
}

class ViewController: NSViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var carregarButton: NSButton!
    @IBOutlet weak var distribuicaoPop: NSPopUpButton!
    @IBOutlet weak var distribuirButton: NSButton!
    @IBOutlet weak var calcularButton: NSButton!
    @IBOutlet weak var outputButton: NSButton!
    @IBOutlet weak var connectionScrollView: NSScrollView!
    @IBOutlet var connectionText: NSTextView!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    //MARK: - Global Variables
    
    var baseFile:String = String()
    var string_lines:[String]!
    var multipeerSession:MultipeerSession!
    var cpf_cnpjHandler:HandlerCPF_CNPJ!
    var timer:Stopwatch!
    
    var allTimers:String = ""
    var higherTimer:Double = 0
    
    var selectedMode:Int?
    
    //MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        self.multipeerSession = MultipeerSession()
        self.multipeerSession.delegate = self
        
        self.connectionText.string = " "
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    //MARK: - Functions
    
    // read the file and creates the list of string
    func readFile() -> Bool {
        let base_file_url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
                .appendingPathComponent("BASEPROJETO")
                .appendingPathExtension("txt")
        
        do {
            self.baseFile = try String(contentsOf: base_file_url, encoding: .utf8)
            self.string_lines = self.baseFile.components(separatedBy: "\n")
            
            return true
        }
        catch {
            print("Can't read file")
        }
        
        return false
    }
    
    // writes the file with the calculated cpfs and cpnjs
    func writeFile() {
        let calculatedFileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .appendingPathComponent("Calculado")
            .appendingPathExtension("txt")
        
        //writing
        do {
            try self.cpf_cnpjHandler.calculatedStrings.write(to: calculatedFileURL, atomically: false, encoding: .utf8)
        }
        catch {/* error handling here */}
    }
    
    // create cpf_cnpj Handler
    func setupHandler() {
        // creates the handler
        self.cpf_cnpjHandler = HandlerCPF_CNPJ(stringList: self.string_lines,
                                               connectedPeers: self.multipeerSession.session.connectedPeers.count,
                                               multipeer: self.multipeerSession, view: self)
        // separate the list for the host and the connected peers
        self.cpf_cnpjHandler.separateLists()
    }
    
    // send the messages to the connected peers
    func sendToPeers() {
        
        self.setupHandler()
        
        // encodes the messages and send them
        for (index, peer) in self.multipeerSession.session.connectedPeers.enumerated() {
            let message = Message(peerHashID: self.multipeerSession.myPeerID.hash,
                                  messageType: MessageType.ToProcess.rawValue,
                                  messageOrder: [index, self.multipeerSession.session.connectedPeers.count],
                                  stringList: self.cpf_cnpjHandler.separatedLists[index + 1])
            
            self.multipeerSession.send(dataToSend: self.multipeerSession.encodeMessage(message: message),
                                       peerToSend: peer)
        }
        
        // updates the label to show that the messages were sent
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Enviado com sucesso!"
        }
    }
    
    // tells peers to start
    func go() {
        let message = Message(peerHashID: self.multipeerSession.myPeerID.hash, messageType: MessageType.Go.rawValue, messageOrder: [])
        let encodedMessage = self.multipeerSession.encodeMessage(message: message)
        
        for (_, peer) in self.multipeerSession.session.connectedPeers.enumerated() {
            self.multipeerSession.send(dataToSend: encodedMessage, peerToSend: peer)
        }
        
    }
    
    //MARK: - IBActions
    
    @IBAction func carregarButtonPressed(_ sender: NSButton) {
        DispatchQueue.main.async {
            self.statusLabel.isHidden = false
            self.statusLabel.stringValue = "Carregando Arquivo..."
        }
        DispatchQueue.global(qos: .default).async {
            if self.readFile() {
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "Arquivo carregado com sucesso!"
                    self.distribuicaoPop.isEnabled = true
                    self.carregarButton.isEnabled = false
                }
            }
        }
    }
    @IBAction func distribuicaoSelected(_ sender: NSPopUpButton) {
        if sender.selectedItem?.title == "Sem Distribuição" {
            self.calcularButton.isEnabled = true
            self.distribuirButton.isEnabled = false
            self.connectionScrollView.isHidden = true
            self.statusLabel.stringValue = "Modo Individual"
            self.multipeerSession.stopHosting()
            self.selectedMode = SelectedMode.Solo.rawValue
        }
        else if sender.selectedItem?.title == "Hospedar Distribuição" {
            self.calcularButton.isEnabled = false
            self.distribuirButton.isEnabled = true
            self.multipeerSession.startHosting()
            self.statusLabel.stringValue = "Hospedando..."
            self.connectionScrollView.isHidden = false
            self.selectedMode = SelectedMode.Host.rawValue
        }
        else {
            self.statusLabel.stringValue = "Selecione o Modo de Operação"
            self.calcularButton.isEnabled = false
            self.distribuirButton.isEnabled = false
            self.connectionScrollView.isHidden = true
            self.selectedMode = nil
        }
    }
    
    @IBAction func distribuirButtonPressed(_ sender: NSButton) {
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Enviando para Peers..."
            self.distribuirButton.isEnabled = false
        }
        self.sendToPeers()
    }
    @IBAction func calcularPressed(_ sender: NSButton) {
        // labels
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Calculando..."
            self.calcularButton.isEnabled = false
            self.distribuicaoPop.isEnabled = false
            self.allTimers = "Tempos dos peers:\n"
            self.connectionText.string = self.allTimers
        }
        // timer
        self.timer = Stopwatch(view: self)
        self.timer.startTimer()
        
        DispatchQueue.global(qos: .default).async {
            self.go()
            if self.selectedMode == SelectedMode.Solo.rawValue {
                self.setupHandler()
            }
            self.cpf_cnpjHandler.calculate()
            DispatchQueue.main.async {
                self.timer.stopTimer()
            }
            
            self.allTimers += "\(self.multipeerSession.myPeerID.displayName) terminou em " + String(format: "%.1f", self.timer.counter) + "s\n"
            
            if self.higherTimer < self.timer.counter {
                self.higherTimer = self.timer.counter
            }

            DispatchQueue.main.async {
                self.connectionScrollView.isHidden = false
                self.connectionText.string = self.allTimers
                self.outputButton.isEnabled = true
                self.statusLabel.stringValue = "Tempo total do calculo: " + String(format: "%.1f", self.higherTimer) + "s\n"
            }
        }
    }
    
    @IBAction func outputButtonPressed(_ sender: NSButton) {
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Salvando Arquivo..."
        }
        self.writeFile()
        DispatchQueue.main.async {
            self.statusLabel.stringValue = "Arquivo Salvo!"
        }
    }
    
}

extension ViewController: MultipeerSessionDelegate {
    
    func messageReceived(manager: MultipeerSession, message: Message, from: MCPeerID) {
        if message.messageType == MessageType.Processed.rawValue {
            self.multipeerSession.send(dataToSend: self.multipeerSession.encodeMessage(message: Message(peerHashID: self.multipeerSession.myPeerID.hash, messageType: MessageType.Received.rawValue, messageOrder: [])), peerToSend: from)
            
            self.allTimers += "\(from.displayName) terminou em " + String(format: "%.1f", self.timer.counter) + "s\n"
            
            if self.higherTimer < message.timeElapsed! {
                self.higherTimer = message.timeElapsed!
            }
            
            DispatchQueue.main.async {
                self.connectionText.string = self.allTimers
            }
            
            self.cpf_cnpjHandler.receivedCalculatedStrings[message.messageOrder[0]] = message.processedString!
            self.cpf_cnpjHandler.receivedResponses += 1
            if self.cpf_cnpjHandler.receivedResponses == self.cpf_cnpjHandler.connectedPeers {
                self.cpf_cnpjHandler.saveResponses()
                DispatchQueue.main.async {
                    self.outputButton.isEnabled = true
                }
            }
        }
        else if message.messageType == MessageType.Received.rawValue {
            self.cpf_cnpjHandler.receivedResponses += 1
            if self.cpf_cnpjHandler.receivedResponses == self.cpf_cnpjHandler.connectedPeers {
                self.cpf_cnpjHandler.receivedResponses = 0
                DispatchQueue.main.async {
                    self.statusLabel.stringValue = "Todos os peers estão prontos!"
                    self.calcularButton.isEnabled = true
                }
            }
        }
    }
    
    func connectedDevicesChanged(manager: MultipeerSession, connectedDevices: [String]) {
        var connected_peers = "Conectado com:\n"
        for peer in connectedDevices {
            connected_peers += peer + "\n"
        }
        DispatchQueue.main.async {
            self.connectionText.string = connected_peers
        }
    }

}

