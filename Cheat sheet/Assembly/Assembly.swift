import Foundation

typealias EntryPoint = UserView & ViewController


protocol UserAssembly {
    var entry: EntryPoint? { get }
    static func start() -> UserAssembly
}


final class Assembly: UserAssembly {
    var entry: EntryPoint?
    static func start() -> UserAssembly {
        let assembly = Assembly()
        let view = ViewController()
        assembly.entry = view as EntryPoint
        return assembly
    }
}
