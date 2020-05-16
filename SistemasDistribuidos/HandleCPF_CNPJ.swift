//
//  HandleCPF_CNPJ.swift
//  SistemasDistribuidos
//
//  Created by Everton Cardoso on 14/05/20.
//  Copyright © 2020 Everton Cardoso. All rights reserved.
//

import Foundation

class HandlerCPF_CNPJ {
    
    var stringList:[String]
    var separatedLists:[[String]] = [[]]
    var receivedCalculatedStrings:[String] = []
    var calculatedStrings:String = String()
    
    let connectedPeers:Int
    
    var receivedResponses:Int = 0
    
    var multipeerSession:MultipeerSession
    
    var viewController:ViewController
    
    init(stringList:[String], connectedPeers:Int, multipeer:MultipeerSession, view:ViewController) {
        self.stringList = stringList
        self.stringList.removeLast()
        self.connectedPeers = connectedPeers
        self.multipeerSession = multipeer
        self.viewController = view
    }
    
    // separates the initial list in connected peers + host
    func separateLists() {
        self.separatedLists = stringList.chunked(into: (self.stringList.count / (connectedPeers + 1)))
        for _ in 0..<connectedPeers{
            self.receivedCalculatedStrings.append("")
        }
    }
    
    // stores the received responses
    func saveResponses() {
        for message in receivedCalculatedStrings {
            self.calculatedStrings += message
        }
    }
    
    // calculates the entire list
    func calculate() {
        // list's first part reserved to the host
        let toCalculate = separatedLists[0]
        
        DispatchQueue.main.async {
            self.viewController.progressBar.isHidden = false
            self.viewController.progressBar.minValue = 0
            self.viewController.progressBar.maxValue = Double(toCalculate.count)
        }
        // iterates for each number
        for (index, valor) in toCalculate.enumerated() {
            // trims the number, removing whitespaces
            let trimmedValor = valor.trimmingCharacters(in: .whitespaces)
            // if number is CPF
            if trimmedValor.count == 9 {
                let result = self.calculateCPF(cpf: trimmedValor)
                self.calculatedStrings += result + "\n"
            } else {
                let result = self.calculateCNPJ(cnpj: trimmedValor)
                self.calculatedStrings += result + "\n"
            }
            DispatchQueue.main.async {
                self.viewController.progressBar.doubleValue = Double(index)
            }
        }
    }
    
    // calculate the verification digit for CPF
    func calculateCPF(cpf:String) -> String {
        var digits = cpf.compactMap{ $0.wholeNumberValue }
        
        var sumDigits = 0
        for (index, number) in digits.enumerated(){
            sumDigits += (number * (10 - index))
        }
        let rest = sumDigits % 11
        var dig10 = 0
        
        if rest != 0 && rest != 1 {
            dig10 = 11 - rest
        }
        
        digits.append(dig10)
        sumDigits = 0
        for (index, number) in digits.enumerated(){
            sumDigits += (number * (11 - index))
        }
        let rest2 = sumDigits % 11
        var dig11 = 0
        
        if rest2 != 0 && rest2 != 1 {
            dig11 = 11 - rest2
        }
        digits.append(dig11)
        
        var calculatedCPF = String()
        
        for index in 0...2 {
            calculatedCPF.append(String(digits[index]))
        }
        calculatedCPF.append(".")
        for index in 3...5 {
            calculatedCPF.append(String(digits[index]))
        }
        calculatedCPF.append(".")
        for index in 6...8 {
            calculatedCPF.append(String(digits[index]))
        }
        calculatedCPF.append("-")
        for index in 9...10 {
            calculatedCPF.append(String(digits[index]))
        }
        
        return calculatedCPF
    }
    
    // calculate the verification digit for CNPJ
    func calculateCNPJ(cnpj:String) -> String {
        var digits = cnpj.compactMap{ $0.wholeNumberValue }
        
        var sumDigits = 0
        for index in 0...3 {
            sumDigits += (digits[index] * (5 - index))
        }
        for index in 4...11 {
            sumDigits += (digits[index] * (13 - index))
        }
        
        let rest = sumDigits % 11
        var dig13 = 0
        
        if rest != 0 && rest != 1 {
            dig13 = 11 - rest
        }
        
        digits.append(dig13)
        sumDigits = 0
        for index in 0...4 {
            sumDigits += (digits[index] * (6 - index))
        }
        for index in 5...12 {
            sumDigits += (digits[index] * (14 - index))
        }
        let rest2 = sumDigits % 11
        var dig14 = 0
        
        if rest2 != 0 && rest2 != 1 {
            dig14 = 11 - rest2
        }
        digits.append(dig14)
        
        var calculatedCNPF = String()
        
        for index in 0...1 {
            calculatedCNPF.append(String(digits[index]))
        }
        calculatedCNPF.append(".")
        for index in 2...4 {
            calculatedCNPF.append(String(digits[index]))
        }
        calculatedCNPF.append(".")
        for index in 5...7 {
            calculatedCNPF.append(String(digits[index]))
        }
        calculatedCNPF.append("/")
        for index in 8...11 {
            calculatedCNPF.append(String(digits[index]))
        }
        calculatedCNPF.append("-")
        for index in 12...13 {
            calculatedCNPF.append(String(digits[index]))
        }
        
        return calculatedCNPF
    }
    
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
