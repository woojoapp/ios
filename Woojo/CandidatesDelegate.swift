//
//  CandidatesDelegate.swift
//  Woojo
//
//  Created by Edouard Goossens on 21/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation

protocol CandidatesDelegate {
    func didAddCandidate()
    func didRemoveCandidate(candidateId: String, index: Int)
}
