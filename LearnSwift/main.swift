//
//  main.swift
//  LearnSwift
//
//  Created by Isaac Dorenkamp on 3/16/21.
//

import Foundation

enum Errors : Error {
    case IllegalState
}

class Record : Hashable {
    
    enum Key {
        case NAME
        case EMAIL
        case AGE
        case ID
        
        func isValidValue<T>(value: T) -> Bool {
            switch(self) {
            case .NAME:
                fallthrough
            case .EMAIL:
                return T.self == String.self
            case .AGE:
                fallthrough
            case .ID:
                return T.self == Int.self
            }
        }
        
        static func fromString(_ str : String) -> Key? {
            switch (str) {
            case "NAME":
                return .NAME
            case "EMAIL":
                return .EMAIL
            case "AGE":
                return .AGE
            case "ID":
                return .ID
            default:
                return nil
            }
        }
    }
    
    enum RecordError : Error {
        case InvalidKeyType
    }
    
    static func == (lhs: Record, rhs: Record) -> Bool {
        return lhs.name == rhs.name && lhs.email == rhs.email && lhs.age == rhs.age
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    private static var NEXT_ID : Int = 0
    
    var name : String
    var email : String
    var age : Int
    private var _id : Int = { () -> Int in
        Record.NEXT_ID += 1
        return Record.NEXT_ID - 1
    }()
    var id : Int {
        get { return _id }
    }
    
    init(name: String, email: String, age: Int) {
        self.name = name
        self.email = email
        self.age = age
    }
    
    func format() -> String {
        return "\(name), age \(age), email \(email), #\(id)"
    }
}

class RecordStore {
    private var records = Set<Record>()
    var all : [Record] {
        return records.sorted(by: { $0.id < $1.id })
    }
    
    func addRecord(rec: Record) {
        records.insert(rec)
    }
    
    func getRecordsByKey<T>(key: Record.Key, value: T) throws -> Set<Record> {
        guard key.isValidValue(value: value) else {
            throw Record.RecordError.InvalidKeyType
        }
        
        var matched = Set<Record>()
        
        switch(key) {
        case .NAME:
            let name : String = value as! String
            for record in records {
                if record.name == name {
                    matched.insert(record)
                }
            }
        case .EMAIL:
            let email : String = value as! String
            for record in records {
                if record.email == email {
                    matched.insert(record)
                }
            }
        case .AGE:
            let age : Int = value as! Int
            for record in records {
                if record.age == age {
                    matched.insert(record)
                }
            }
        case .ID:
            let id : Int = value as! Int
            for record in records {
                if record.id == id {
                    matched.insert(record)
                }
            }
        }
        
        return matched
    }
    
    func addRecord(_ rec: Record) {
        records.insert(rec)
    }
}

class Stack<T> {
    private var arr = [T]()
    
    var isEmpty : Bool {
        return arr.isEmpty
    }
    
    func push(_ value: T) {
        arr.append(value)
    }
    
    @discardableResult
    func pop() -> T? {
        guard !arr.isEmpty else {
            return nil
        }
        
        return arr.popLast()
    }
    
    func peek() -> T? {
        guard !arr.isEmpty else {
            return nil
        }
        
        return arr.last
    }
}

protocol Activity {
    var prompt : String { get }
    
    func onStart()
    // Handle a line of input returns true to exit and false to continue
    func handleInput(_ input: String) -> Bool
    func onFinish()
}

class ActivityManager {
    private var activities = Stack<Activity>()
    
    func push(_ act: Activity) {
        activities.push(act)
        act.onStart()
    }
    
    func start(_ act: Activity) throws {
        guard activities.isEmpty else {
            throw Errors.IllegalState
        }
        
        push(act)
        mainloop()
    }
    
    private func mainloop() {
        while !activities.isEmpty {
            let activity : Activity = activities.peek()!
            print(activity.prompt, terminator: "")
            let input = readLine() ?? ""
            let shouldExit = activity.handleInput(input)
            if shouldExit {
                activity.onFinish()
                activities.pop()
            }
        }
    }
}

struct MenuOption {
    let label: String
    let invoke: () -> Bool
}

class MenuActivity : Activity {
    private var procedures = [MenuOption]()
    private var title : String
    private var _prompt : String
    var prompt : String {
        return _prompt
    }
    
    init(title: String, prompt: String) {
        self.title = title
        self._prompt = prompt
    }
    
    convenience init(title: String) {
        self.init(title: title, prompt: "> ")
    }
    
    func addOption(_ opt : MenuOption) {
        procedures.append(opt)
    }
    
    func addOption(label: String, invoke: @escaping () -> Bool) {
        addOption(MenuOption(label: label, invoke: invoke))
    }
    
    func printMenu() {
        for (index, option) in procedures.enumerated() {
            print("\(index + 1). \(option.label)")
        }
    }
    
    func onStart() {
        print(title)
        print("\n")
        printMenu()
        print()
    }
    
    func handleInput(_ input: String) -> Bool {
        let _option : Int? = Int(input)
        if var option = _option {
            option -= 1
            if option < procedures.count && option >= 0 {
                let proc : MenuOption = procedures[option]
                let shouldExit = proc.invoke()
                return shouldExit
            } else {
                print("Invalid option \(option + 1)")
            }
        } else {
            print("Invalid option \(input)")
        }
        return false
    }
    
    func onFinish() {}
}

// Program Code
class AddRecordActivity : Activity {
    var ref : RecordStore
    
    private var step : Int = 0
    private var rec = Record(name: "", email: "", age: 0)
    var prompt : String {
        switch(step) {
        case 0:
            return "Enter the name: "
        case 1:
            return "Enter the email address: "
        case 2:
            return "Enter the age: "
        default:
            return "Uh oh, I'm lost!"
        }
    }
    
    init(_ ref : RecordStore) {
        self.ref = ref
    }
    
    func onStart() {}
    
    func handleInput(_ input : String) -> Bool {
        switch(step) {
        case 0:
            rec.name = input
            step += 1
        case 1:
            rec.email = input // we're not worried about validation lol
            step += 1
        case 2:
            let _age = Int(input)
            if let age = _age {
                if age < 0 {
                    print("Invalid age. Try again.")
                } else {
                    rec.age = age
                    return true
                }
            } else {
                print("Invalid age. Try again.")
            }
        default:
            return true
        }
        
        return false
    }
    
    func onFinish() {
        print("Added record #\(rec.id)")
        ref.addRecord(rec)
    }
}

class QueryRecordsActivity : Activity {
    private var ref : RecordStore
    private var step : Int = 0
    private var key : Record.Key?
    var prompt : String {
        switch(step) {
        case 0:
            return "Key to query by (name, email, age, ID): "
        case 1:
            return "Enter value to find records matching: "
        default:
            return "Oh no"
        }
    }
    
    init(_ ref : RecordStore) {
        self.ref = ref
    }
    
    func onStart() {}
    
    func handleInput(_ input: String) -> Bool {
        switch (step) {
        case 0:
            key = Record.Key.fromString(input.uppercased())
            if key != nil {
                step += 1
            } else {
                print("Invalid key '\(input).'")
            }
        case 1:
            var rec : Set<Record>
            switch(key!) {
            case .NAME:
                rec = try! ref.getRecordsByKey(key: .NAME, value: input)
            case .EMAIL:
                rec = try! ref.getRecordsByKey(key: .EMAIL, value: input)
            case .AGE:
                let _age = Int(input)
                if let age = _age {
                    rec = try! ref.getRecordsByKey(key: .AGE, value: age)
                } else {
                    print("Invalid age \(input)")
                    return false
                }
            case .ID:
                let _id = Int(input)
                if let id = _id {
                    rec = try! ref.getRecordsByKey(key: .ID, value: id)
                } else {
                    print("Invalid ID \(input)")
                    return false
                }
            }
            
            print()
            
            if rec.isEmpty {
                print("No records found.")
            } else {
                print("Records Found")
                print("=============")
                for record in rec.sorted(by: { $0.id < $1.id }) {
                    print(record.format())
                }
            }
            
            print()
            
            return true
        default:
            return true
        }
        return false
    }
    
    func onFinish() {}
}

func main() {
    let records = RecordStore()
    
    let runner = ActivityManager()
    let base = MenuActivity(title: "Record Tracker v1.0")
    base.addOption(label: "Add Record", invoke: { () -> Bool in
        runner.push(AddRecordActivity(records))
        return false
    })
    base.addOption(label: "List Records", invoke: { () -> Bool in
        for rec in records.all {
            print(rec.format())
        }
        return false
    })
    base.addOption(label: "Query Records", invoke: { () -> Bool in
        runner.push(QueryRecordsActivity(records))
        return false
    })
    base.addOption(label: "Exit", invoke: { () -> Bool in return true })
    
    try! runner.start(base)
}

main()
