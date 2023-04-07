//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

struct MSALNativeAuthSignUpStartResponseError: MSALNativeAuthResponseError {

    let error: MSALNativeAuthSignUpStartOauth2ErrorCode
    let errorDescription: String?
    let errorURI: String?
    let innerErrors: [MSALNativeAuthInnerError]?
    let signUpToken: String?
    let verifyAttributes: [[String: String]]?
    let invalidAttributes: [[String: String]]?

    init(
        error: MSALNativeAuthSignUpStartOauth2ErrorCode,
        errorDescription: String? = nil,
        errorURI: String? = nil,
        innerErrors: [MSALNativeAuthInnerError]? = nil,
        signUpToken: String? = nil,
        verifyAttributes: [[String: String]]? = nil,
        invalidAttributes: [[String: String]]? = nil
    ) {
        self.error = error
        self.errorDescription = errorDescription
        self.errorURI = errorURI
        self.innerErrors = innerErrors
        self.signUpToken = signUpToken
        self.verifyAttributes = verifyAttributes
        self.invalidAttributes = invalidAttributes
    }

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case errorURI = "error_uri"
        case innerErrors = "inner_errors"
        case signUpToken = "signup_token"
        // TODO: change for verify_attributes when mock api fixes it
        case verifyAttributes = "attributes_to_verify"
        case invalidAttributes = "invalid_attributes"
    }
}
