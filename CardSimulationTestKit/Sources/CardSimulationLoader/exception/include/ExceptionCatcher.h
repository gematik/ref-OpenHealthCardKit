//
//  Copyright (c) 2024 gematik GmbH
//
//  Licensed under the Apache License, Version 2.0 (the License);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an 'AS IS' BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

/**
 Catch NSExceptions from ObjC dependencies.

 To use this function create a Bridging-Header and import this header file.
 Then you'll just have to call:

 ```swift
 if let error = gemTryBlock({
    // Execute code that can raise NSException(s)
 }) {
    // Handle the exception/error
    print("An exception was thrown!", error.localizedDescription)
 }
 ```
 */
NS_INLINE NSException * _Nullable gemTryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}
