//
//  ImageController.swift
//  Created by Steven O'Toole on 10/17/17.
//  https://github.com/JustinM1/S3SignerAWS
//  https://github.com/BrettRToomey/brett-xml
import Foundation
import Vapor
import S3SignerAWS
import HTTP
import BML  // XML Parser

final class ImageController: Controlling {
    fileprivate static let bucketName = "mouldypnakotic1" // "nyarlathotepbrous"
    fileprivate let log: LogProtocol
    fileprivate let client: ClientFactoryProtocol
    fileprivate let s3Signer: S3SignerAWS?
    fileprivate let presignedURLPrefix = "https://s3-us-west-1.amazonaws.com/\(ImageController.bucketName)/"
    fileprivate let presignedURLLifeInMinutes = 5

    init(log: LogProtocol, client: ClientFactoryProtocol, s3Signer: S3SignerAWS?) throws {
        self.log = log
        self.client = client
        self.s3Signer = s3Signer
    }

    func addOpenRoutes(drop: Droplet) {
        drop.get("vendings/images", String.parameter) { req in
            let vendingID = try req.parameters.next(String.self)
            return try self.s3ListGrandKids(grandParentDir: "vendings", parentDir: vendingID)
        }
    }

    func addGroupedRoutes(group: RouteBuilder) {
        group.get("profile", String.parameter, String.parameter) { req in
            return try self.profilePresigned(httpMethod: .get, req: req)
        }

        group.delete("profile", String.parameter, String.parameter) { req in
            let folderID = try req.parameters.next(String.self)
            let fileName = try req.parameters.next(String.self)
            return try self.s3DeleteObject(grandParentDir: "profiles", parentDir: folderID, objectName: fileName)
        }

        group.get("profile/upload", String.parameter, String.parameter) { req in
            return try self.profilePresigned(httpMethod: .put, req: req)
        }

        group.get("vendings/image/upload", String.parameter, String.parameter) { req in
            return try self.vendingPresigned(httpMethod: .put, req: req)
        }

        group.delete("vendings/image", String.parameter, String.parameter) { req in
            let vendingID = try req.parameters.next(String.self)
            let imageName = try req.parameters.next(String.self)
            return try self.s3DeleteObject(grandParentDir: "vendings", parentDir: vendingID, objectName: imageName)
        }
    }

    fileprivate func vendingPresigned(httpMethod: HTTPMethod, req: Request, headers: [String: String] = [:])
    throws -> JSON {
        let folderID = try req.parameters.next(String.self)
        let fileName = try req.parameters.next(String.self)
        let dirPrefix = "vendings/\(folderID)"
        return try self.s3GetPresignedJSON(httpMethod: httpMethod, dirPrefix: dirPrefix, fileName: fileName)
    }

    fileprivate func profilePresigned(httpMethod: HTTPMethod, req: Request, headers: [String: String] = [:])
    throws -> JSON {
        let folderID = try req.parameters.next(String.self)
        let fileName = try req.parameters.next(String.self)
        let dirPrefix = "profiles/\(folderID)"
        return try self.s3GetPresignedJSON(httpMethod: httpMethod, dirPrefix: dirPrefix, fileName: fileName)
    }

    // 10/17/17-headers don't work: "The request signature we calculated does not match the signature you provided"
    // let headers = ["x-amz-storage-class": "REDUCED_REDUNDANCY"]
    fileprivate func s3GetPresignedJSON(httpMethod: HTTPMethod, headers: [String: String] = [:],
                                    dirPrefix: String, fileName: String)
    throws -> JSON {
        guard let s3Signer = self.s3Signer else {
            return try JSON(node: ["status": 501, "message": "S3 Config error"])
        }
        let urlString = "\(self.presignedURLPrefix)\(dirPrefix)/\(fileName)".lowercased()
        let presignedURL = try s3Signer.presignedURLV4(httpMethod: httpMethod, urlString: urlString,
                                                       expiration: .custom(60 * self.presignedURLLifeInMinutes),
                                                       headers: headers)
        return try JSON(node: ["status": 200, "iurl": presignedURL])
    }

    fileprivate func s3GetPresignedURL(httpMethod: HTTPMethod, headers: [String: String] = [:],
                                    dirPrefix: String, fileName: String)
    throws -> String? {
        guard let s3Signer = self.s3Signer else { return nil }
        let urlString = "\(self.presignedURLPrefix)\(dirPrefix)/\(fileName)".lowercased()
        let presignedURL = try s3Signer.presignedURLV4(httpMethod: httpMethod, urlString: urlString,
                                                       expiration: .custom(60 * self.presignedURLLifeInMinutes),
                                                       headers: headers)
        return presignedURL
    }

    func s3TestRoutes(drop: Droplet) {
        drop.delete("s3vending", String.parameter, String.parameter) { req in
            let vendingID = try req.parameters.next(String.self)
            let imageName = try req.parameters.next(String.self)
            return try self.s3DeleteObject(grandParentDir: "vendings", parentDir: vendingID, objectName: imageName)
        }

        drop.get("s3list/vending", String.parameter) { req in
            let vendingID = try req.parameters.next(String.self)
            return try self.testVendingListing(vendingID: vendingID)
        }
        drop.get("iget", String.parameter, String.parameter) { req in
            return try self.testPresigned(httpMethod: .get, req: req)
        }
        drop.get("iput", String.parameter, String.parameter) { req in
            // headers don't work: "The request signature we calculated does
            // not match the signature you provided"
            // let headers = ["x-amz-storage-class": "REDUCED_REDUNDANCY"]
            return try self.testPresigned(httpMethod: .put, req: req)
        }
    }

    fileprivate func testVendingListing(vendingID: String) throws -> JSON {
        return try s3ListGrandKids(grandParentDir: "vendings", parentDir: vendingID)
    }

    fileprivate func s3ListGrandKids(grandParentDir: String, parentDir: String) throws -> JSON {
        guard let s3Signer = self.s3Signer else {
            return try JSON(node: ["status": 501, "message": "S3 Config error"])
        }
        // I will make a convention that all image names have a numeric prefix beginning with zero.
        // This prevents the call from returning the parent directory key.
        let prefix = "prefix=\(grandParentDir)/\(parentDir)/".lowercased()
        let urlString = "https://\(ImageController.bucketName).s3.amazonaws.com/?list-type=2&\(prefix)"
        let headers = try s3Signer.authHeaderV4(
            httpMethod: .get,
            urlString: urlString,
            headers: [:],
            payload: .none)

        let vaporHeaders = headers.vaporHeaders
        let req = Request(method: .get, uri: urlString, headers: vaporHeaders)
        let response = try client.respond(to: req)
        return try presignedListFromBodyXML(response: response, dirPrefix: "\(grandParentDir)/\(parentDir)")
    }

    fileprivate func s3DeleteObject(grandParentDir: String, parentDir: String, objectName: String) throws -> JSON {
        guard let s3Signer = self.s3Signer else {
            return try JSON(node: ["status": 501, "message": "S3 Config error"])
        }
        let path = "/\(grandParentDir)/\(parentDir)/\(objectName)".lowercased()
        let urlString = "https://\(ImageController.bucketName).s3.amazonaws.com\(path)"
        print("->\(urlString)")
        let headers = try s3Signer.authHeaderV4(
            httpMethod: .delete,
            urlString: urlString,
            headers: [:],
            payload: .none)
        let vaporHeaders = headers.vaporHeaders
        let req = Request(method: .delete, uri: urlString, headers: vaporHeaders)
        print("->req\n\(req)")
        let response = try client.respond(to: req)
        return try JSON(node: [
            "status": response.status.statusCode, "headers": response.headers.description
        ])
    }

    fileprivate func presignedListFromBodyXML(response: Response, dirPrefix: String) throws -> JSON {
        guard let bytes = response.body.bytes else { return try Utility.noBody() }
        let node = try XMLParser.parse(bytes)
        let objectCountString = node["KeyCount"]?.value ?? "0"
        let objectCount = Int(objectCountString) ?? 0
        var childArray = [String]()
        for child in node.children {
            if child.name != "Contents" { continue }
            guard let key = child["Key"]?.value, let keyName = fileNameFromPath(key) else { continue }
            if let presigned = try s3GetPresignedURL(httpMethod: .get,
                                                     dirPrefix: dirPrefix.lowercased(),
                                                     fileName: keyName.lowercased()) {
                childArray.append(presigned)
            }
        }
        return try JSON(node: [
            "status": 200, "topname": node.name, "objectCount": objectCount,
            "children": childArray
        ])
    }

    fileprivate func fileNameFromPath(_ path: String) -> String? {
        let components = path.components(separatedBy: "/")
        if components.last == "" { return nil }
        return components.last
    }

    fileprivate func testPresigned(httpMethod: HTTPMethod, req: Request, headers: [String: String] = [:])
    throws -> JSON {
        let folderID = try req.parameters.next(String.self)
        let fileName = try req.parameters.next(String.self)
        return try self.s3GetPresignedJSON(httpMethod: httpMethod, dirPrefix: folderID, fileName: fileName)
    }

}

// https://s3-us-west-1.amazonaws.com/nyarlathotep.tenebrous/test/seal.jpg?
// X-Amz-Algorithm=AWS4-HMAC-SHA256 &
// X-Amz-Credential=AKIAIXF376XK5QV6BOKA%2F20171016%2Fus-west-1%2Fs3%2Faws4_request &
// X-Amz-Date=20171016T231340Z &
// X-Amz-Expires=300 &
// X-Amz-SignedHeaders=host &
// X-Amz-Signature=4fda408e5dd98c752ee8d5964b43e9cc990e314ebe61071fd8d98db5c34d27bd

