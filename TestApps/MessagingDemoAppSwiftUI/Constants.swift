/*
Copyright 2023 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import Foundation

enum Constants {
    // If you change any of the below properties, please uninstall and reinstall the application
    
    static let APPID = "staging/1b50a869c4a2/9590f35e2dc9/launch-752d0a90822f-development"
    // Other AppID's
    // "3149c49c3910/b6541e5e6301/launch-f7ac0a320fb3-development"
    // "staging/1b50a869c4a2/bcd1a623883f/launch-e44d085fc760-development"
    
    static let isStage = true
    static let assuranceURL = "edgetutorialapp://?adb_validation_sessionid=6d2f49c1-630b-4ae3-9966-82b02c6961f3&env=stage"
    
    // Surface Names
    enum SurfaceName {
        static let CONTENT_CARD = "cardstab"
        static let CBE_HTML = "cbehtml"
        static let CBE_JSON = "cbejson"
    }
}
