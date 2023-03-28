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

@_implementationOnly import MSAL_Private

final class MSALNativeAuthRequestErrorHandler: NSObject, MSIDHttpRequestErrorHandling {

    // swiftlint:disable function_parameter_count cyclomatic_complexity function_body_length
    func handleError(
        _ error: Error?,
        httpResponse: HTTPURLResponse?,
        data: Data?,
        httpRequest: MSIDHttpRequestProtocol?,
        responseSerializer: MSIDResponseSerialization?,
        context: MSIDRequestContext?,
        completionBlock: MSIDHttpRequestDidCompleteBlock?) {
        guard httpResponse != nil else {
            if let completionBlock = completionBlock {
                completionBlock(nil, error)
            }
            return
        }
        var shouldRetry = true
        shouldRetry = (httpRequest?.retryCounter ?? 0) > 0
        // 5xx Server errors.
        shouldRetry = shouldRetry && httpResponse?.statusCode ?? 0 >= 500 && httpResponse?.statusCode ?? 0 <= 599
        if shouldRetry {
            httpRequest?.retryCounter -= 1
            if let context = context {
                MSALLogger.log(level: .verbose,
                               context: context,
                               format: "Retrying network request, retryCounter: %d", httpRequest?.retryCounter ?? 0)
            }

            let deadline = DispatchTime.now() + Double(UInt64(httpRequest?.retryInterval ?? 0) * NSEC_PER_SEC )
            DispatchQueue.main.asyncAfter(deadline: deadline) {
                httpRequest?.send(completionBlock)
            }

            return
        }

        // pkeyauth challenge
        if httpResponse?.statusCode == 400 || httpResponse?.statusCode == 401 {
            let wwwAuthValue = httpResponse?.allHeaderFields[kMSIDWwwAuthenticateHeader] as? String
            if !NSString.msidIsStringNilOrBlank(wwwAuthValue),
               let wwwAuthValue = wwwAuthValue,
               wwwAuthValue.contains(kMSIDPKeyAuthName) {
                MSIDPKeyAuthHandler.handleWwwAuthenticateHeader(wwwAuthValue,
                                                                request: httpRequest?.urlRequest.url,
                                                                context: context) { authHeader, completionError in
                    if !NSString.msidIsStringNilOrBlank(authHeader) {
                        // append auth header
                        if let newRequest = (httpRequest?.urlRequest as? NSURLRequest)?
                            .mutableCopy() as? NSMutableURLRequest {
                            newRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
                            httpRequest?.urlRequest = newRequest as URLRequest

                            DispatchQueue.main.async {
                                httpRequest?.send(completionBlock)
                            }
                        }
                        return
                    }
                    if let completionBlock = completionBlock {
                        completionBlock(nil, completionError)
                    }
                }
                return
            }

            do {
                let responseErrorObject = try JSONDecoder()
                    .decode(MSALNativeAuthErrorRequestResponse.self, from: data ?? Data())
                if let completionBlock = completionBlock {
                    completionBlock(responseErrorObject, error)
                }
            } catch {
                if let completionBlock = completionBlock {
                    completionBlock(nil, error)
                }
            }
            return
        }

        if let statusCode = httpResponse?.statusCode {
            let errorDescription = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            if let context = context {
                MSALLogger.log(level: .warning,
                               context: context,
                               format: "Http error raised. Http Code: %d Description %@", statusCode,
                               MSALLogMask.maskPII(errorDescription))
            }

            var additionalInfo = [AnyHashable: Any]()
            additionalInfo[MSIDHTTPHeadersKey] = httpResponse?.allHeaderFields
            additionalInfo[MSIDHTTPResponseCodeKey] = String(httpResponse?.statusCode ?? 0)

            if statusCode >= 500, statusCode <= 599 {
                additionalInfo[MSIDServerUnavailableStatusKey] = NSNumber(value: 1)
            }

            if let context = context {
                let httpError  = MSIDCreateError(MSIDHttpErrorCodeDomain,
                                                 MSIDErrorCode.serverUnhandledResponse.rawValue,
                                                 errorDescription,
                                                 nil,
                                                 nil,
                                                 nil,
                                                 context.correlationId(),
                                                 additionalInfo,
                                                 true)
                if let completionBlock = completionBlock {
                    completionBlock(nil, httpError)
                }
            }
        }
    }
    // swiftlint:enable function_parameter_count cyclomatic_complexity function_body_length
}
