//
//  VKGLES2View.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKGLES2View.h"

#pragma mark - GLSL vertex & pixel shaders

NSString *const stringShaderVertex = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texCoordIn;
 varying vec2 texCoordOut;
 uniform mat4 projectionMatrix;

 void main() {
     gl_Position = projectionMatrix * position;
     texCoordOut = texCoordIn;
 }
 );

#pragma mark - VKGLES2View Implementation

const GLfloat texCoords[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 0.0f,
};

@interface VKGLES2View () {

    /* OpenGL ES properties */
    GLuint _framebuffer;
    GLint _backingWidth;
    GLint _backingHeight;
    
    /* managing gl according to decode manager */
    VKDecodeManager *_decodeManager;
    float _ratio;
    CGSize _superViewSize;
    
#ifdef TRIAL
    //TRIAL
    UILabel *_labelTrial;
    UILabel *_labelTrialInfo;
    NSTimer *_timerTrialUIUpdate;
#endif
}

@end

@implementation VKGLES2View

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor blackColor];
        [self enableRetina:YES];

        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (int)initGLWithDecodeManager:(VKDecodeManager *)decoder bounds:(CGRect)bounds {

    _decodeManager = decoder;
    _ratio = 1.0;
    _colorFormat = [_decodeManager videoStreamColorFormat];
    _position = 0;
    _texCoordIn = 1;
    self.frame = [self exactFrameRectForSize:bounds.size fillScreen:NO];

    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:TRUE], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                    nil];

    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!_context ||
        ![EAGLContext setCurrentContext:_context]) {
        VKLog(kVKLogLevelOpenGL, @"Error: Failed to set current openGL context");
        return -1;
    }

    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
    
    GLenum err = 0;

    err = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (err != GL_FRAMEBUFFER_COMPLETE) {
        VKLog(kVKLogLevelOpenGL, @"Error: Could not generate frame buffer: %d", err);
        return -1;
    }
    
#ifdef TRIAL
    int timeout = (arc4random()%10) + 3;
    _timerTrialUIUpdate = [[NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(onTimerTrialUIUpdateFired:) userInfo:nil repeats:YES] retain];
    [self performSelector:@selector(onTimerTrialUIUpdateFired:)];
#endif
    
    [self updateVertices];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNewFrame:) name:kVKVideoFrameReadyForRenderNotification object:_decodeManager];
    
#if TARGET_OS_IOS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRotation:) name:UIDeviceOrientationDidChangeNotification object:nil];
#endif
    
    return 0;
}

- (void)enableRetina:(BOOL)value {
    if (value) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ( [UIScreen instancesRespondToSelector:@selector(nativeScale)] )
        {
            self.contentScaleFactor = [UIScreen mainScreen].nativeScale;
        }
        else
#endif
        {
            self.contentScaleFactor = [UIScreen mainScreen].scale;
        }
    } else
        self.contentScaleFactor = 1.0;
}

- (void)updateOpenGLFrameSizes {
    VKLog(kVKLogLevelUIControlExtra, @"VKGLES2View->onRotation");
    [EAGLContext setCurrentContext:_context];
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        VKLog(kVKLogLevelOpenGL, @"Error: Framebuffer get failed %x", status);
    } else {
        VKLog(kVKLogLevelOpenGL, @"Info: GLView Vertices updated for %d:%d",  _backingWidth, _backingHeight);
    }
    [self renderFrameToTexture:nil];
    VKLog(kVKLogLevelOpenGL,@"updateOpenGLFrameSizes");
}

- (void)updateVertices {
    float h = 1.0;
    float w = 1.0;
    
    _vertices[0] = - w;
    _vertices[1] = - h;
    _vertices[2] =   w;
    _vertices[3] = - h;
    _vertices[4] = - w;
    _vertices[5] =   h;
    _vertices[6] =   w;
    _vertices[7] =   h;
}

- (void)onNewFrame:(NSNotification *)theNotification {
    if ([self window]) {
        VKVideoFrame *vidFrame = [[theNotification userInfo] objectForKey:kVKVideoFrame];
        if (_ratio != vidFrame.aspectRatio) {
            _ratio = vidFrame.aspectRatio;
            self.frame = [self exactFrameRectForSize:_superViewSize fillScreen:_fillScreen];
            [self updateOpenGLFrameSizes];
            [[self superview] setNeedsLayout];
            [[self superview] layoutIfNeeded];
        }
        [self renderFrameToTexture:vidFrame];
    }
}

- (void)renderFrameToTexture:(VKVideoFrame *)vidFrame {
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    eaglLayer.opaque = YES;
    
    if ([self.backgroundColor isEqual:[UIColor blackColor]]) {
        glClearColor(0.0, 0.0, 0.0, 1.0);
    } else if ([self.backgroundColor isEqual:[UIColor whiteColor]]) {
        glClearColor(1.0, 1.0, 1.0, 1.0);
    } else if ([self.backgroundColor isEqual:[UIColor clearColor]]) {
        glClearColor(0.0, 0.0, 0.0, 0.0);
        eaglLayer.opaque = NO;
    } else {
        CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0;
        [self.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
        glClearColor(red, green, blue, alpha);
    }
    
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
}

- (void)updateProjectionMatrix {
    double frameAngle = [_decodeManager videoFramesAngle];
     GLKMatrix4 projMat = GLKMatrix4Identity;
    if (frameAngle != 0) {
        projMat = GLKMatrix4Rotate(GLKMatrix4Identity, GLKMathDegreesToRadians(frameAngle), 0, 0, 1);
    }
    glUniformMatrix4fv(_projectionUniformMatrix, 1, 0, projMat.m);
}

- (CGRect)exactFrameRectForSize:(CGSize)boundsSize fillScreen:(BOOL)fillScreen {
    float decWidth = [_decodeManager frameWidth] * _ratio;
    float decHeight  = [_decodeManager frameHeight];
    
    double frameAngle = [_decodeManager videoFramesAngle];
    if (frameAngle == VK_DISPLAY_MATRIX_ANGLE_PORTRAIT) {
        //this is a portrait frame
        decWidth = [_decodeManager frameHeight];
        decHeight = [_decodeManager frameWidth] * _ratio;
    }
    
    _superViewSize = boundsSize;
    
    if ((decWidth * decHeight) > 0) {
        const float ratioWidth =  boundsSize.width/decWidth;
        const float ratioHeight = boundsSize.height/decHeight;
        
        float ratio = 1.0;
        if (fillScreen) {
            if (boundsSize.height > boundsSize.width) {
                ratio = MIN(ratioWidth, ratioHeight);
            } else {
                ratio = MAX(ratioWidth, ratioHeight);
            }
        } else {
            ratio = MIN(ratioWidth, ratioHeight);
        }
        
        float hRect = ratio * decHeight;
        float yRect = (boundsSize.height - hRect)/2.0;
        float wRect = ratio * decWidth;
        float xRect = (boundsSize.width - wRect)/2.0;
        
        CGRect r = CGRectIntegral(CGRectMake(xRect, yRect, wRect, hRect));
        return r;
    }
    return CGRectMake(0.0, 0.0, boundsSize.width, boundsSize.height);
}

- (UIImage *)snapshot {
    
    const BOOL fit      = (self.contentMode == UIViewContentModeScaleAspectFit);
    const float decWidth   = [_decodeManager frameWidth] * _ratio;
    const float decHeight  = [_decodeManager frameHeight];
    const float dH      = (float)_backingHeight / decHeight;
    const float dW      = (float)_backingWidth	  / decWidth;
    const float dd      = fit ? MIN(dH, dW) : MAX(dH, dW);
    const float h       = decHeight * dd;
    const float w       = decWidth  * dd;
    
    NSInteger x = (_backingWidth - w)/2, y = (_backingHeight - h)/2, width = w, height = h;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    // Read pixel data from the framebuffer
    [EAGLContext setCurrentContext:_context];
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glReadPixels((int)x, (int)y, (int)width, (int)height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    // Create a CGImage with the pixel data
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    // otherwise, use kCGImageAlphaPremultipliedLast
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    // OpenGL ES measures data in PIXELS
    // Create a graphics context with the target size measured in POINTS
    NSInteger widthInPoints, heightInPoints;
    if (NULL != &UIGraphicsBeginImageContextWithOptions) {
        // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
        // Set the scale parameter to your OpenGL ES view's contentScaleFactor
        // so that you get a high-resolution snapshot when its value is greater than 1.0
        CGFloat scale = self.contentScaleFactor;
        widthInPoints = width / scale;
        heightInPoints = height / scale;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    }
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    
    // Retrieve the UIImage from the current context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // Clean up
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    
    return image;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    VKLog(kVKLogLevelUIControlExtra, @"VKGLES2View->layoutSubviews");
    if (!_stopUpdateGLSize) {
        [self updateOpenGLFrameSizes];
    }
}

#pragma mark - Rotation

- (void)onRotation:(NSNotification *)theNotification {
    VKLog(kVKLogLevelUIControlExtra, @"VKGLES2View->onRotation");
}

#pragma mark - TRIAL

#ifdef TRIAL
- (void)onTimerTrialUIUpdateFired:(NSTimer *)timer {
    [self removeUITrial];
    [self addUITrial];
}

- (void)addUITrial {

    float hTrial = 20.0;
    float wTrial = 120.0;
    float yTrial = (self.bounds.size.height - hTrial)/2.0;
    float xTrial = (self.bounds.size.width - wTrial)/2.0;
    _labelTrial = [[UILabel alloc] initWithFrame:CGRectMake(xTrial, yTrial, wTrial, hTrial)];
    _labelTrial.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _labelTrial.opaque = NO;
    _labelTrial.backgroundColor = [UIColor blackColor];
    _labelTrial.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12];
    _labelTrial.text = @"TRIAL VERSION";
    _labelTrial.textColor = [UIColor redColor];
    _labelTrial.lineBreakMode = NSLineBreakByTruncatingTail;
    _labelTrial.minimumScaleFactor = 0.3;
    _labelTrial.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_labelTrial];

    float hTrialInfo = 20.0;
    float wTrialInfo = 120.0;
    float marginY = 5.0;
    float yTrialInfo = (self.bounds.size.height - hTrialInfo)/2.0 + hTrialInfo + marginY;
    float xTrialInfo = (self.bounds.size.width - wTrialInfo)/2.0;
    _labelTrialInfo = [[UILabel alloc] initWithFrame:CGRectMake(xTrialInfo, yTrialInfo, wTrialInfo, hTrialInfo)];
    _labelTrialInfo.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _labelTrialInfo.opaque = NO;
    _labelTrialInfo.backgroundColor = [UIColor clearColor];
    _labelTrialInfo.font = [UIFont fontWithName:@"HelveticaNeue" size:10];
    _labelTrialInfo.text = @"iosvideokit.com";
    _labelTrialInfo.shadowColor = [UIColor blackColor];
    _labelTrialInfo.shadowOffset = CGSizeMake(-1, -1);
    _labelTrialInfo.textColor = [UIColor orangeColor];
    _labelTrialInfo.lineBreakMode = NSLineBreakByTruncatingTail;
    _labelTrialInfo.minimumScaleFactor = 0.3;
    _labelTrialInfo.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_labelTrialInfo];
}

- (void)removeUITrial {
    if (_labelTrial && [_labelTrial superview]) {
        [_labelTrial removeFromSuperview];
        [_labelTrial release];
        _labelTrial = nil;
    }

    if (_labelTrialInfo && [_labelTrialInfo superview]) {
        [_labelTrialInfo removeFromSuperview];
        [_labelTrialInfo release];
        _labelTrialInfo = nil;
    }
}

- (NSArray *)subviews {
    return nil;
}

#endif

#pragma mark - Handle shaders ~ compile & bind attr,uniforms

- (int)linkProgram {
    GLint status = GL_FALSE;
    
    _program = glCreateProgram();
    glAttachShader(_program, _vertexShader);
    glAttachShader(_program, _fragmentShader);

    glBindAttribLocation(_program, _position, "position");
    glBindAttribLocation(_program, _texCoordIn, "texCoordIn");

    glLinkProgram(_program);

    GLint linkSuccess = GL_FALSE;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);

    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        VKLog(kVKLogLevelOpenGL, @"Error: gl link error %@", messageString);
        goto error;
    }

    glValidateProgram(_program);
    glGetProgramiv(_program, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
        VKLog(kVKLogLevelOpenGL, @"Error: gl validate error %d", _program);
        goto error;
    }
    
    return 0;
    
error:

    if (_vertexShader)
        glDeleteShader(_vertexShader);
    if (_fragmentShader)
        glDeleteShader(_fragmentShader);

    if (!status) {
        glDeleteProgram(_program);
        _program = 0;
    }
    return -1;
}

- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType
{
    GLuint shaderHandle = glCreateShader(shaderType);
    if (shaderHandle == 0 || shaderHandle == GL_INVALID_ENUM) {
        VKLog(kVKLogLevelOpenGL, @"Error: gl shader can not be created %d", shaderType);
        return -1;
    }

    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);

    glCompileShader(shaderHandle);

    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        VKLog(kVKLogLevelOpenGL, @"Error: glsl source can not be compiled %@", messageString);
        return -1;
    }
    return shaderHandle;
}

#pragma mark - Shutdown

- (void)shutdown {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [EAGLContext setCurrentContext:_context];
    
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }

    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }

    if (_vertexShader)
        glDeleteShader(_vertexShader);
    if (_fragmentShader)
        glDeleteShader(_fragmentShader);

    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }

	if ([EAGLContext currentContext] == _context) {
		[EAGLContext setCurrentContext:nil];
	}

    [_context release];
	_context = nil;
    
#ifdef TRIAL
    [_timerTrialUIUpdate invalidate];
    [_timerTrialUIUpdate release];
    
    [_labelTrial release];
    [_labelTrialInfo release];
#endif
    
}

- (void)dealloc {
    VKLog(kVKLogLevelOpenGL, @"GLView is deallocated");
    [super dealloc];
}

@end
