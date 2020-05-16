//
//  Timer.swift
//  SistemasDistribuidos
//
//  Created by Everton Cardoso on 14/05/20.
//  Copyright © 2020 Everton Cardoso. All rights reserved.
//

import Foundation

class Stopwatch {
    
    //MARK: - Variables and Constants
    
    // time elapsed in seconds
    var counter:Double = 0.0
    
    // timer instance
    var timer:Timer!
    
    // if the timer is running
    var isPlaying = false
    
    // ViewController
    var viewController:ViewController
    
    //MARK: - Functions
    
    init(view: ViewController) {
        self.viewController = view
    }
    
    // start the timer
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        isPlaying = true
    }
    
    // updates de counter
    @objc func updateTimer() {
        self.counter += 0.1
        self.updateLabel()
    }
    
    // Updates the label with the current elapsed time in minutes, seconds and 1/10 sec
    func updateLabel() {
        DispatchQueue.main.async {
            self.viewController.statusLabel.stringValue = "Tempo decorrido: " + String(format: "%.1f", self.counter) + "s"
        }
    }
    
    // stops the timer
    func stopTimer() {
        self.timer.invalidate()
        self.isPlaying = false
    }
    
    // resets the timer
    func resetTimer() {
        self.counter = 0.0
        self.timer = Timer()
    }
    
}
