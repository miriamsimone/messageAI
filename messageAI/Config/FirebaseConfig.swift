#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseConfig {
    static func configure() {
#if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
#else
        debugPrint("FirebaseCore not linked. Add Firebase SDK before running the app.")
#endif
    }
}

