//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import RxSwift
import Promises

extension Observable {
    func toPromise() -> Promise<Element> {
        return Promise<Element> { fulfill, reject in
            _ = self.take(1).asSingle().subscribe(onSuccess: {
                fulfill($0)
            }, onError: {
                reject($0)
            })
        }
    }
}
