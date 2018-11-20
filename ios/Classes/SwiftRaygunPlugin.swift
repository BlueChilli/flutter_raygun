import Flutter
import UIKit
import Raygun4iOS

class FlutterCrash: Error {
    
}

func Log(msg: String, _ args:[CVarArg] = [])
{
    NSLogv(msg, getVaList(args));
}


public class SwiftRaygunPlugin: NSObject, FlutterPlugin, RaygunOnBeforeSendDelegate {
    
  var isRaygunInitialized = false
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_raygun", binaryMessenger: registrar.messenger())
    let instance = SwiftRaygunPlugin()
    registrar.addApplicationDelegate(instance);
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func on(beforeSend message: RaygunMessage!) -> Bool {
    
    let mainBundle = Bundle.main;
    let appName = mainBundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    let bundleId = mainBundle.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
    let appVersion = mainBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    let buildNumber = mainBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    let appdata = [
        "appName": appName ?? "",
        "bundleId": bundleId ?? "",
        "appVersion": appVersion ?? "",
        "buildNumber": buildNumber ?? "",
        ];
    
    if(message.details.userCustomData != nil) {
        let stacktrace = message.details.userCustomData["stacktraces"] as? [Any];
        let errorMessage = message.details.error;
        message.details.error.stackTrace = stacktrace;
        message.details.userCustomData = message.details.userCustomData.merging(appdata, uniquingKeysWith: { (item1:Any, item2:Any) -> Any in
            return item1
        })
    }
    else {
        message.details.userCustomData = appdata;
    }
    
    return true;
  }
    
  private func buildStackTrace(traces: Array<Dictionary<String, Any>>?) -> [FlutterStackFrame] {
    var stacks = [FlutterStackFrame]()

    traces?.forEach {trace in
        let className: String = trace["class"] as? String ?? ""
        let methodName: String = trace["method"] as? String ?? ""
        let libraryName: String = trace["library"] as? String ?? ""
        let frame = FlutterStackFrame(symbol: "\(className).\(methodName)")
        frame.library = className
        frame.rawSymbol = className
        frame.fileName = libraryName
        if let ln = trace["line"] as? Int {
            frame.lineNumber = UInt32(ln)
        }
        stacks.append(frame)
    }
    return stacks
  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "initialize" {
            let parameters = (call.arguments as! Dictionary<String, Any>);
            let apikey = parameters["apikey"] as? String;
            let usePulse = parameters["pulse"] as? Bool ?? false;
            let networkLogging = parameters["networkingLogging"] as? Bool ?? false;
            let raygun = Raygun.sharedReporter(withApiKey: apikey, withCrashReporting: true) as! Raygun;
            if(usePulse) {
                raygun.attachPulse(withNetworkLogging: networkLogging);
            }
            raygun.onBeforeSendDelegate = self;
            
            isRaygunInitialized = true;
            result(nil)
        } else if(isRaygunInitialized) {
            onInitialisedMethodCall(call, result: result)
        } else {
            // Should not result in an error. Otherwise Opt Out clients would need to handle errors
            result(nil)
        }
    }
  
    private func onInitialisedMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let raygun = Raygun.sharedReporter() as! Raygun
        
        switch call.method {
        case "reportCrash":
            let exception = (call.arguments as! Dictionary<String, Any>)
            let cause = exception["cause"] as? String
            let message = exception["message"] as? String
            let traces = exception["trace"] as? Array<Dictionary<String, Any>>
            let forceCrash = exception["forceCrash"] as? Bool ?? false
            let tags = exception["tags"] as? Array<String> ?? []
            let data = exception["data"] as? Dictionary<String, Any> ?? [:]
            let stacks = buildStackTrace(traces: traces)
            
            if(forceCrash) {
                try! crash(cause ?? "Flutter Error", reason: message ?? "", frameArray: stacks)
            }
            else {
                let ex = FlutterException(name: NSExceptionName(rawValue: cause ?? "Flutter Error"), reason: message, frameArray: stacks)
                let merged = data.merging(["stacktraces": ex.callStackSymbols]) { (item1:Any, item2:Any) -> Any in
                    return item1;
                }
                
                raygun.send(ex, withTags:tags, withUserCustomData: merged);
            }
            result(nil)
            break
        case "log":
            let info = call.arguments as! Dictionary<String, Any>
            let send = info["send"] as? Bool ?? false
            let msg = info["message"] as? String
            let tags = info["tags"] as? Array<String> ?? []
           
            if(send) {
              raygun.send("Log", withReason:msg, withTags: tags, withUserCustomData: nil)
            }

            Log(msg: "%@: %@ %@", ["FlutterRaygun", msg!])
            result(nil)
            break
        case "setInfo":
            let info = call.arguments as! Dictionary<String, Any>
            raygun.setValue(info["value"], forKey: info["key"] as! String)
            result(nil)
            break
        case "setTags":
            let tags = call.arguments as! Array<String>
            raygun.tags = tags;
        case "setUserInfo":
            let info = call.arguments as! Dictionary<String, String>
            let userInfo = RaygunUserInfo(identifier: info["id"], withEmail: info["email"], withFullName: info["name"], withFirstName: info["firstname"])
            raygun.identify(with: userInfo);
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func crash(_ cause: String, reason: String, frameArray: Array<FlutterStackFrame>) throws{
        Log(msg: "%@ %@", [cause, reason])
        frameArray.forEach { (line) in
            Log(msg: "%@", [line.description])
        }
        let ex = FlutterException(name: NSExceptionName(rawValue: cause), reason: reason, frameArray: frameArray)
        
        ex.raise()
        //throw ex
    }
}

class FlutterException: NSException, Error {
    let frameArray: Array<FlutterStackFrame>
    init(name aName: NSExceptionName, reason aReason: String?, frameArray: Array<FlutterStackFrame>) {
        self.frameArray = frameArray
        super.init(name: aName, reason: aReason, userInfo: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        frameArray = []
        super.init(coder: aDecoder)
    }
    
    override var callStackSymbols: [String] {
        return frameArray.map({ (frame) -> String in
            return "\(frame.description)"
        })
    }
    
    
}

class FlutterStackFrame: NSObject {
    
    init(address:UInt64) {
        self.address = address;
        self.symbol = "";
        self.rawSymbol = "";
        self.library = "";
        self.fileName = ""
        self.lineNumber = 0;
        self.offset = 0;
    }
    
    init(symbol:String) {
        self.symbol = symbol;
        self.rawSymbol = "";
        self.library = "";
        self.fileName = ""
        self.lineNumber = 0;
        self.offset = 0;
        self.address = 0;
        
       
    }
    
    var symbol: String;
    var rawSymbol: String;
    var library:String;
    var fileName:String;
    var lineNumber:UInt32;
    var offset:UInt64;
    var address:UInt64;
    
    override var description: String {
        return "\(self.symbol) lib:\(self.library) (\(self.fileName)) line: \(self.lineNumber)"
    }
    

}
