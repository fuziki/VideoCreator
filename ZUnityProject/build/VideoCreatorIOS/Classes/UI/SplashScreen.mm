#include "SplashScreen.h"
#include "UnityViewControllerBase.h"
#include "OrientationSupport.h"
#include "Unity/ObjCRuntime.h"
#include "UI/UnityView.h"
#include <cstring>

extern "C" const char* UnityGetLaunchScreenXib();

#include <utility>

static SplashScreen*            _splash      = nil;
static SplashScreenController*  _controller  = nil;
static bool                     _isOrientable = false; // true for iPads and iPhone 6+
static bool                     _usesLaunchscreen = false;
static ScreenOrientation        _nonOrientableDefaultOrientation = portrait;

// we will create and show splash before unity is inited, so we can use only plist settings
static bool _canRotateToPortrait            = false;
static bool _canRotateToPortraitUpsideDown  = false;
static bool _canRotateToLandscapeLeft       = false;
static bool _canRotateToLandscapeRight      = false;

#if !PLATFORM_TVOS
typedef id (*WillRotateToInterfaceOrientationSendFunc)(struct objc_super*, SEL, UIInterfaceOrientation, NSTimeInterval);
typedef id (*DidRotateFromInterfaceOrientationSendFunc)(struct objc_super*, SEL, UIInterfaceOrientation);
#endif
typedef id (*ViewWillTransitionToSizeSendFunc)(struct objc_super*, SEL, CGSize, id<UIViewControllerTransitionCoordinator>);

static const char* GetScaleSuffix(float scale, float maxScale)
{
    if (scale > maxScale)
        scale = maxScale;
    if (scale <= 1.0)
        return "";
    if (scale <= 2.0)
        return "@2x";
    return "@3x";
}

static const char* GetOrientationSuffix(ScreenOrientation orient)
{
    bool orientPortrait  = (orient == portrait || orient == portraitUpsideDown);
    bool orientLandscape = (orient == landscapeLeft || orient == landscapeRight);

    bool rotateToPortrait  = _canRotateToPortrait || _canRotateToPortraitUpsideDown;
    bool rotateToLandscape = _canRotateToLandscapeLeft || _canRotateToLandscapeRight;

    if (orientPortrait && rotateToPortrait)
        return "-Portrait";
    else if (orientLandscape && rotateToLandscape)
        return "-Landscape";
    else if (rotateToPortrait)
        return "-Portrait";
    else
        return "-Landscape";
}

// Returns a launch image name for launch images stored on file system or asset catalog
static NSArray<NSString*>* GetLaunchImageNames(UIUserInterfaceIdiom idiom, const CGSize& screenSize,
    ScreenOrientation orient)
{
    NSMutableArray<NSString*>* ret = [[NSMutableArray<NSString *> alloc] init];

    if (idiom == UIUserInterfaceIdiomPad)
    {
        // iPads
        const char* iOSSuffix = "-700";
        const char* orientSuffix = GetOrientationSuffix(orient);
        const char* scaleSuffix = GetScaleSuffix([UIScreen mainScreen].scale, 2.0);
        [ret addObject: [NSString stringWithFormat: @"LaunchImage%s%s%s~ipad",
                         iOSSuffix, orientSuffix, scaleSuffix]];
    }
    else
    {
        // iPhones
        float scale = [UIScreen mainScreen].scale;

        // Note that on pre-iOS 11 using modifiers such as LaunchImage~568h works. Since
        // iOS launch image support is quite hard to get right and has _many_ gotchas, we
        // just use the old code path on these devices.

        if (screenSize.height == 568 || screenSize.width == 568) // iPhone 5
        {
            const char* iOS7Suffix = _ios70orNewer ? "-700" : "";

            [ret addObject: [NSString stringWithFormat: @"LaunchImage%s-568h@2x", iOS7Suffix]];
            [ret addObject: @"LaunchImage~568h"];
        }
        else if (screenSize.height == 667 || screenSize.width == 667) // iPhone 6
        {
            // note that scale may be 3.0 if display zoom is enabled
            if (scale < 2.0) // not expected, but handle just in case. Image name is valid
                [ret addObject: @"LaunchImage-800-667h"];
            [ret addObject: @"LaunchImage-800-667h@2x"];
            [ret addObject: @"LaunchImage~667h"];
        }
        else if (screenSize.height == 736 || screenSize.width == 736) // iPhone 6+
        {
            const char* orientSuffix = GetOrientationSuffix(orient);
            if (scale < 3.0) // not expected, but handle just in case. Image name is valid
                [ret addObject: [NSString stringWithFormat: @"LaunchImage-800%s-736h", orientSuffix]];
            [ret addObject: [NSString stringWithFormat: @"LaunchImage-800%s-736h@3x", orientSuffix]];
            [ret addObject: @"LaunchImage~736h"];
        }
        else if (screenSize.height == 812 || screenSize.width == 812) // iPhone X
        {
            const char* orientSuffix = GetOrientationSuffix(orient);
            if (scale < 3.0) // not expected, but handle just in case. Image name is valid
                [ret addObject: [NSString stringWithFormat: @"LaunchImage-1100%s-2436h", orientSuffix]];
            [ret addObject: [NSString stringWithFormat: @"LaunchImage-1100%s-2436h@3x", orientSuffix]];
        }

        if (scale > 1.0)
            [ret addObject: @"LaunchImage@2x"];
    }
    [ret addObject: @"LaunchImage"];
    return ret;
}

@implementation SplashScreen
{
    UIImageView* m_ImageView;
    UIView* m_XibView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame: frame];
    return self;
}

/* The following launch images are produced by Xcode6:

    LaunchImage.png
    LaunchImage@2x.png
    LaunchImage-568h@2x.png
    LaunchImage-700@2x.png
    LaunchImage-700-568h@2x.png
    LaunchImage-700-Landscape@2x~ipad.png
    LaunchImage-700-Landscape~ipad.png
    LaunchImage-700-Portrait@2x~ipad.png
    LaunchImage-700-Portrait~ipad.png
    LaunchImage-800-667h@2x.png
    LaunchImage-800-Landscape-736h@3x.png
    LaunchImage-800-Portrait-736h@3x.png
    LaunchImage-1100-Landscape-2436h@3x.png
    LaunchImage-1100-Portrait-2436h@3x.png
    LaunchImage-Landscape@2x~ipad.png
    LaunchImage-Landscape~ipad.png
    LaunchImage-Portrait@2x~ipad.png
    LaunchImage-Portrait~ipad.png
*/
- (void)updateOrientation:(ScreenOrientation)orient
{
    CGFloat scale = UnityScreenScaleFactor([UIScreen mainScreen]);
    UnityReportResizeView(self.bounds.size.width * scale, self.bounds.size.height * scale, orient);
    ReportSafeAreaChangeForView(self);

    // Storyboards should have a view controller to automatically configure orientation
    bool hasStoryboard = [[NSBundle mainBundle] pathForResource: @"LaunchScreen" ofType: @"storyboardc"] != nullptr;
    if (hasStoryboard)
        return;

    UIUserInterfaceIdiom idiom = [[UIDevice currentDevice] userInterfaceIdiom];

    NSString* xibName = nil;
    if (idiom == UIUserInterfaceIdiomPhone)
        xibName = @"LaunchScreen-iPhone";
    else if (idiom == UIUserInterfaceIdiomPad)
        xibName = @"LaunchScreen-iPad";

    bool hasLaunchScreen = [[NSBundle mainBundle] pathForResource: xibName ofType: @"nib"] != nullptr;

    if (_usesLaunchscreen && hasLaunchScreen)
    {
        // Launch screen uses the same aspect-filled image for all iPhone and/or
        // all iPads, as configured in Unity. We need a special case if there's
        // a launch screen and iOS is configured to use it.
        if (self->m_XibView == nil)
        {
            self->m_XibView = [[[NSBundle mainBundle] loadNibNamed: xibName owner: nil options: nil] objectAtIndex: 0];
            [self addSubview: self->m_XibView];
        }
        return;
    }

    UIImage* image = nil;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;

    // For launch images we implement fallback order with multiple images. First we try images via
    // [UIImage imageNamed] method and if this fails, we try to load from filesystem directly.
    // Note that file system resource names and image names accepted by UIImage are the same.
    // Multiple fallbacks are implemented because different iOS versions behave differently and have
    // many gotchas that are hard to get right. So we use the images that are present on app bundles
    // made with latest version of Xcode as the first priority and then fall back to any image that we
    // have used at some time in the past.
    NSArray<NSString*>* imageNames = GetLaunchImageNames(idiom, screenSize, orient);

    for (NSString* imageName in imageNames)
    {
        image = [UIImage imageNamed: imageName];
        if (image)
            break;
    }

    if (image == nil)
    {
        // Old launch image from file
        for (NSString* imageName in imageNames)
        {
            image = [UIImage imageNamed: imageName];
            if (image)
                break;

            NSString* imagePath = [[NSBundle mainBundle] pathForResource: imageName ofType: @"png"];
            image = [UIImage imageWithContentsOfFile: imagePath];
            if (image)
                break;
        }
    }

    // should not ever happen, but just in case
    if (image == nil)
        return;

    if (self->m_ImageView == nil)
    {
        self->m_ImageView = [[UIImageView alloc] initWithImage: image];
        [self addSubview: self->m_ImageView];
    }
    else
    {
        self->m_ImageView.image = image;
    }
}

- (void)layoutSubviews
{
    if (self->m_XibView)
        self->m_XibView.frame = self.bounds;
    else if (self->m_ImageView)
        self->m_ImageView.frame = self.bounds;
}

+ (SplashScreen*)Instance
{
    return _splash;
}

- (void)FreeSubviews
{
    m_ImageView = nil;
    m_XibView = nil;
}

@end

@implementation SplashScreenController

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    ScreenOrientation curOrient = UIViewControllerOrientation(self);
    ScreenOrientation newOrient = OrientationAfterTransform(curOrient, [coordinator targetTransform]);

    if (_isOrientable)
        [_splash updateOrientation: newOrient];

    [coordinator animateAlongsideTransition: nil completion:^(id < UIViewControllerTransitionCoordinatorContext > context) {
        if (!_isOrientable)
            OrientView(self, _splash, _nonOrientableDefaultOrientation);
    }];
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
}

- (void)create:(UIWindow*)window
{
    NSArray* supportedOrientation = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"UISupportedInterfaceOrientations"];
    bool isIphone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    bool isIpad = !isIphone;

    // splash will be shown way before unity is inited so we need to override autorotation handling with values read from info.plist
    _canRotateToPortrait            = [supportedOrientation containsObject: @"UIInterfaceOrientationPortrait"];
    _canRotateToPortraitUpsideDown  = [supportedOrientation containsObject: @"UIInterfaceOrientationPortraitUpsideDown"];
    _canRotateToLandscapeLeft       = [supportedOrientation containsObject: @"UIInterfaceOrientationLandscapeRight"];
    _canRotateToLandscapeRight      = [supportedOrientation containsObject: @"UIInterfaceOrientationLandscapeLeft"];

    CGSize size = [[UIScreen mainScreen] bounds].size;

    // iPads and iPhone Plus models and iOS11 have orientable splash screen
    _isOrientable = isIpad || (size.height == 736 || size.width == 736) || _ios110orNewer;

    // Launch screens are used only on iOS8+ iPhones
    const char* xib = UnityGetLaunchScreenXib();
#if !PLATFORM_TVOS
    _usesLaunchscreen = false;
    if (xib != NULL)
    {
        const char* expectedName = isIphone ? "LaunchScreen-iPhone" : "LaunchScreen-iPad";
        if (std::strcmp(xib, expectedName) == 0)
            _usesLaunchscreen = true;
    }
#else
    _usesLaunchscreen = false;
#endif

    if (_usesLaunchscreen && !(_canRotateToPortrait || _canRotateToPortraitUpsideDown))
        _nonOrientableDefaultOrientation = landscapeLeft;
    else
        _nonOrientableDefaultOrientation = portrait;

    _splash = [[SplashScreen alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    _splash.contentScaleFactor = [UIScreen mainScreen].scale;

    if (_isOrientable)
    {
        _splash.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _splash.autoresizesSubviews = YES;
    }
    else if (_canRotateToPortrait || _canRotateToPortraitUpsideDown)
    {
        _canRotateToLandscapeLeft = false;
        _canRotateToLandscapeRight = false;
    }
    // On non-orientable devices with launch screens, landscapeLeft is always used if both
    // landscapeRight and landscapeLeft are enabled
    if (!_isOrientable && _usesLaunchscreen && _canRotateToLandscapeRight)
    {
        if (_canRotateToLandscapeLeft)
            _canRotateToLandscapeRight = false;
        else
            _nonOrientableDefaultOrientation = landscapeRight;
    }

    bool hasStoryboard = [[NSBundle mainBundle] pathForResource: @"LaunchScreen" ofType: @"storyboardc"] != nullptr;

    window.rootViewController = self;

    if (!hasStoryboard)
    {
        self.view = _splash;

        [window addSubview: _splash];
        [window bringSubviewToFront: _splash];

        ScreenOrientation orient = UIViewControllerOrientation(self);
        [_splash updateOrientation: orient];

        if (!_isOrientable)
            orient = _nonOrientableDefaultOrientation;

        OrientView([SplashScreenController Instance], _splash, orient);
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger ret = 0;

    if (_canRotateToPortrait)
        ret |= (1 << UIInterfaceOrientationPortrait);
    if (_canRotateToPortraitUpsideDown)
        ret |= (1 << UIInterfaceOrientationPortraitUpsideDown);
    if (_canRotateToLandscapeLeft)
        ret |= (1 << UIInterfaceOrientationLandscapeRight);
    if (_canRotateToLandscapeRight)
        ret |= (1 << UIInterfaceOrientationLandscapeLeft);

    return ret;
}

+ (SplashScreenController*)Instance
{
    return _controller;
}

@end

void ShowSplashScreen(UIWindow* window)
{
    bool hasStoryboard = [[NSBundle mainBundle] pathForResource: @"LaunchScreen" ofType: @"storyboardc"] != nullptr;

    if (hasStoryboard)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName: @"LaunchScreen" bundle: [NSBundle mainBundle]];
        _controller = [storyboard instantiateViewControllerWithIdentifier: @"unitySplashStoryboard"];
    }
    else
        _controller = [[SplashScreenController alloc] init];

    [_controller create: window];
    [window makeKeyAndVisible];
}

void HideSplashScreen()
{
    if (_splash)
    {
        [_splash removeFromSuperview];
        [_splash FreeSubviews];
    }

    _splash = nil;
    _controller = nil;
}
