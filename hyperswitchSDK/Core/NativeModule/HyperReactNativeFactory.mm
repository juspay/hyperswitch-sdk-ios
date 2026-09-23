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

+ (NSArray<NSString *> *)initialChunks
{
  return @[ @"hyperswitch.react-native.chunk.bundle", @"hyperswitch.vendors.chunk.bundle" ];
}

+ (NSString *)missingFilesForBundleURL:(NSURL *)bundleURL resourceDirectory:(NSString *)resourceDirectory
{
  if (bundleURL == nil) {
    return @"the entry bundle";
  }
  if (!bundleURL.isFileURL) {
    return nil; // A development server serves it.
  }
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSMutableArray<NSString *> *missing = [NSMutableArray array];
  if (![fileManager fileExistsAtPath:bundleURL.path]) {
    [missing addObject:bundleURL.lastPathComponent];
  }
  NSString *bundleDir = bundleURL.URLByDeletingLastPathComponent.path;
  for (NSString *chunk in self.initialChunks) {
    BOOL inBundleDir = [fileManager fileExistsAtPath:[bundleDir stringByAppendingPathComponent:chunk]];
    BOOL inResources = resourceDirectory != nil &&
        [fileManager fileExistsAtPath:[resourceDirectory stringByAppendingPathComponent:chunk]];
    if (!inBundleDir && !inResources) {
      [missing addObject:chunk];
    }
  }
  return missing.count > 0 ? [missing componentsJoinedByString:@", "] : nil;
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

  for (NSString *chunk in HyperReactNativeFactory.initialChunks) {
    NSString *path = [bundleDir stringByAppendingPathComponent:chunk];
    if (![fileManager fileExistsAtPath:path] && _resourceDirectory != nil) {
      // The download and the packaged copy must come from the same SDK build, so OTA
      // packages are expected to ship every chunk file.
      NSString *packaged = [_resourceDirectory stringByAppendingPathComponent:chunk];
      if ([fileManager fileExistsAtPath:packaged]) {
        RCTLogWarn(@"[Hyperswitch] %@ has no %@; using the packaged copy", bundleDir, chunk);
        path = packaged;
      }
    }
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
    if (data != nil) {
      [self evaluate:data url:[NSURL fileURLWithPath:path].absoluteString inRuntime:runtime];
    }
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
