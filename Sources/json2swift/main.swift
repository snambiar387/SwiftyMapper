import Foundation

// MARK: - JSON Parsing & Model Generation

func swiftType(for value: Any, propertyName: String, modelDefinitions: inout [String: String], optional: Bool) -> String {
    let baseType: String
    
    switch value {
    case is Int:
        baseType = "Int"
    case is Double:
        baseType = "Double"
    case is Bool:
        baseType = "Bool"
    case is String:
        baseType = "String"
    case let dict as [String: Any]:
        let structName = propertyName.capitalizedFirstLetter()
        modelDefinitions[structName] =
        generateSwiftModel(from: dict, modelName: structName, modelDefinitions: &modelDefinitions)
        baseType = structName
    case let array as [Any]:
        if let firstElement = array.first {
            let elementType = swiftType(for: firstElement, propertyName: propertyName, modelDefinitions: &modelDefinitions, optional: optional)
            baseType = "[\(elementType)]"
        } else {
            baseType = "[Any]"
        }
    default:
        baseType = "Any"
    }
    
    return optional ? "\(baseType)?" : baseType
}

func generateSwiftModel(from json: [String: Any], modelName: String, modelDefinitions: inout [String: String]) -> String {
    var properties = ""
    var codingKeys = ""
    
    for (key, value) in json {
        let propertyName = key.camelCased()
        let optional = value is NSNull
        let propertyType = swiftType(for: value, propertyName: propertyName, modelDefinitions: &modelDefinitions, optional: optional)
        
        properties += "    let \(propertyName): \(propertyType)\n"
        
        if propertyName != key {
            codingKeys += "        case \(propertyName) = \"\(key)\"\n"
        }
    }
    
    var model = "struct \(modelName): \(modelType) {\n\(properties)"
    
    if !codingKeys.isEmpty {
        model += "\n    enum CodingKeys: String, CodingKey {\n\(codingKeys)    }\n"
    }
    
    model += "}\n"
    
    return model
}

// MARK: - Command Line Arguments Handling

let args = CommandLine.arguments

// Mapping short flags to long options
var options = [String: String]()
var modelType = "Decodable"

var i = 1
while i < args.count {
    switch args[i] {
    case "-i", "--input":
        if i + 1 < args.count { options["input"] = args[i + 1] }
        i += 1

    case "-o", "--output":
        if i + 1 < args.count { options["output"] = args[i + 1] }
        i += 1
    case "-m", "--model":
        if i + 1 < args.count { options["model"] = args[i + 1] }
        i += 1
    case "-t", "--type":
        if i + 1 < args.count { modelType = args[i + 1] }
        i += 1
    default:
        print("Unknown argument: \(args[i])")
        exit(1)

    }
    i += 1
}

// Extract parsed options
guard let filePath = options["input"] else {
    print("Usage: json2swift <input.json> [-o output.swift] [-m ModelName] [-c] [-t Codable|Decodable]")
    exit(1)
}

let outputFilePath = options["output"]
let modelName = options["model"] ?? "RootModel"

// Read JSON
guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
      let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
    print("Error: Could not read or parse JSON file.")
    exit(1)
}

// Generate Swift model
var modelDefinitions = [String: String]()
let rootModel = generateSwiftModel(from: jsonObject, modelName: modelName, modelDefinitions: &modelDefinitions)

// Combine all model definitions
let finalSwiftCode = ([rootModel] + modelDefinitions.values).joined(separator: "\n")

// Output or save to file
if let outputPath = outputFilePath {
    try? finalSwiftCode.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
    print("Swift model saved to \(outputPath)")
} else {
    print(finalSwiftCode)
}

// MARK: - String Extensions

extension String {
    func camelCased() -> String {
        let components = self.components(separatedBy: "_")
        let first = components.first?.lowercased() ?? ""
        let rest = components.dropFirst().map { $0.capitalized }.joined()
        return first + rest
    }

    func capitalizedFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}
