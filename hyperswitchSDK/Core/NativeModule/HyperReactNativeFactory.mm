//
//  HyperReactNativeFactory.mm
//  Hyperswitch
//
//  See HyperReactNativeFactory.h.
//

#import "HyperReactNativeFactory.h"

#import <React/RCTLog.h>
#import <ReactCommon/RCTHost.h>
#import <jsi/jsi.h>

#include <memory>
#include <string>

namespace {

/// Hands the bytes of an NSData to the JS engine without copying them.
class NSDataBuffer : public facebook::jsi::Buffer {
 public:
  explicit NSDataBuffer(NSData *data) : data_(data) {}
  size_t size() const override
  {
    return data_.length;
  }
  const uint8_t *data() const override
  {
    return static_cast<const uint8_t *>(data_.bytes);
  }

 private:
  NSData *data_;
};

NSString *const kChunkSuffix = @".chunk.bundle";
NSString *const kRuntimeChunk = @"react-native";

} // namespace

@implementation HyperReactNativeFactory {
  NSString *_resourceDirectory;
}

- (instancetype)initWithDelegate:(id<RCTReactNativeFactoryDelegate>)delegate
               resourceDirectory:(NSString *)resourceDirectory
{
  if (self = [super initWithDelegate:delegate]) {
    _resourceDirectory = [resourceDirectory copy];
  }
  return self;
}

+ (NSString *)runtimeChunkNameForBundle:(NSString *)bundleFileName
{
  NSString *name = [bundleFileName hasSuffix:@".bundle"] ? [bundleFileName stringByDeletingPathExtension]
                                                         : bundleFileName;
  return [NSString stringWithFormat:@"%@.%@%@", name, kRuntimeChunk, kChunkSuffix];
}

#pragma mark - RCTHostDelegate

// RCTReactNativeFactory is the host's delegate but does not implement this; RCTHost
// calls it on the JS thread once the runtime exists, before the entry bundle runs.
- (void)host:(RCTHost *)host didInitializeRuntime:(facebook::jsi::Runtime &)runtime
{
  NSURL *bundleURL = [self.delegate bundleURL];
  if (bundleURL == nil || !bundleURL.isFileURL) {
    return; // A development server serves an unsplit bundle.
  }

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *bundleDir = bundleURL.URLByDeletingLastPathComponent.path;
  NSArray<NSString *> *bundleFiles = [fileManager contentsOfDirectoryAtPath:bundleDir error:nil] ?: @[];

  NSMutableDictionary *layout = [NSMutableDictionary dictionary];
  layout[@"bundleDir"] = bundleDir;
  layout[@"bundleFiles"] = bundleFiles;
  layout[@"resourceDir"] = _resourceDirectory ?: [NSNull null];
  NSData *layoutJSON = [NSJSONSerialization dataWithJSONObject:layout options:0 error:nil];
  if (layoutJSON != nil) {
    NSString *script = [NSString stringWithFormat:@"globalThis.__HYPERSWITCH_SCRIPTS__=%@;",
                                                  [[NSString alloc] initWithData:layoutJSON
                                                                        encoding:NSUTF8StringEncoding]];
    [self evaluate:[script dataUsingEncoding:NSUTF8StringEncoding]
               url:@"hyperswitch-bundle-layout.js"
         inRuntime:runtime];
  }

  NSString *runtimeName = [HyperReactNativeFactory runtimeChunkNameForBundle:bundleURL.lastPathComponent];
  NSString *runtimePath = [bundleDir stringByAppendingPathComponent:runtimeName];
  if (![fileManager fileExistsAtPath:runtimePath] && _resourceDirectory != nil) {
    // The download and the packaged copy must come from the same SDK build, so OTA
    // packages are expected to ship every chunk file.
    NSString *packaged = [_resourceDirectory stringByAppendingPathComponent:runtimeName];
    if ([fileManager fileExistsAtPath:packaged]) {
      RCTLogWarn(@"[Hyperswitch] %@ has no %@; using the packaged copy", bundleDir, runtimeName);
      runtimePath = packaged;
    }
  }
  NSData *runtimeChunk = [NSData dataWithContentsOfFile:runtimePath options:NSDataReadingMappedIfSafe error:nil];
  if (runtimeChunk != nil) {
    [self evaluate:runtimeChunk url:[NSURL fileURLWithPath:runtimePath].absoluteString inRuntime:runtime];
  }
}

- (void)evaluate:(NSData *)script url:(NSString *)url inRuntime:(facebook::jsi::Runtime &)runtime
{
  try {
    runtime.evaluateJavaScript(std::make_shared<NSDataBuffer>(script), std::string(url.UTF8String));
  } catch (const std::exception &e) {
    // The entry reports the missing runtime itself; this says why.
    RCTLogError(@"[Hyperswitch] Could not evaluate %@: %s", url, e.what());
  }
}

@end
