//
//  VKGLES2ViewYUVVT.m
//  VideoKitSample
//
//  Created by Murat Sudan on 19/08/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKGLES2ViewYUVVT.h"

// BT.601, which is the standard for SDTV.
static const GLfloat kColorConversion601[] = {
    1.164,  1.164, 1.164,
    0.0,   -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
    1.164,  1.164,  1.164,
    0.0,   -0.213,  2.112,
    1.793, -0.533,  0.0,
};

static NSString *const stringShaderFragmentYUVVT = SHADER_STRING
(
 precision mediump float;
 varying highp vec2 texCoordOut;
 uniform sampler2D s_texture_y;
 uniform sampler2D s_texture_uv;
 uniform mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = (texture2D(s_texture_y, texCoordOut).r - (16.0/255.0));
     yuv.yz = (texture2D(s_texture_uv, texCoordOut).rg - vec2(0.5, 0.5));
     rgb = colorConversionMatrix * yuv;
     gl_FragColor = vec4(rgb,1);
 }
 );


@interface VKGLES2View ()
- (void)renderFrameToTexture:(VKVideoFrame *)vidFrame;
- (void)updateProjectionMatrix;
- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType;
- (int)linkProgram;
@end

@interface VKGLES2ViewYUVVT () {
    GLint _uniformVT;
    GLint _uniformYUVVT[2];
    GLuint _texYUVVT[2];
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef      _cvTexturesRef[2];
    const GLfloat *_preferredConversion;
}

@end

@implementation VKGLES2ViewYUVVT

- (int)initGLWithDecodeManager:(VKDecodeManager *)decoder bounds:(CGRect)bounds {
    
    int err = [super initGLWithDecodeManager:decoder bounds:bounds];
    if (err == 0) {
        err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_textureCache);
        if (err) {
            VKLog(kVKLogLevelOpenGL, @"Error at CVOpenGLESTextureCacheCreate %d\n", err);
            return NO;
        }
        
        err = [self compileShaderAndLinkProgram];
        if (err) {
            VKLog(kVKLogLevelOpenGL, @"Error: Could not compile or link shaders");
            return -1;
        }
    }
    return err;
}

- (void)renderFrameToTexture:(VKVideoFrame *)vidFrame {
    
    [super renderFrameToTexture:vidFrame];
    
    if (vidFrame) {
        [self renderFrame:(VKVideoFrameYUVVT *)vidFrame];
    }
    
    if (0 != _texYUVVT[0]) {
        glVertexAttribPointer(_position, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(_position);
        glVertexAttribPointer(_texCoordIn, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(_texCoordIn);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderFrame:(VKVideoFrameYUVVT *)vidFrame {
    
    CVPixelBufferRef pixelBuffer = vidFrame.pixelBuffer;
    if (!pixelBuffer) {
        VKLog(kVKLogLevelOpenGL, @"nil pixelBuffer in overlay\n");
        return;
    }
    
    CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
        _preferredConversion = kColorConversion601;
    } else if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_709_2){
        _preferredConversion = kColorConversion709;
    } else {
        _preferredConversion = kColorConversion601;
    }
    
    for (int i = 0; i < 2; ++i) {
        if (_cvTexturesRef[i]) {
            CFRelease(_cvTexturesRef[i]);
            _cvTexturesRef[i] = 0;
            _texYUVVT[i] = 0;
        }
    }
    
    // Periodic texture cache flush every frame
    if (_textureCache)
        CVOpenGLESTextureCacheFlush(_textureCache, 0);
    
    if (_texYUVVT[0])
        glDeleteTextures(2, _texYUVVT);
    
    size_t frameWidth  = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                 _textureCache,
                                                 pixelBuffer,
                                                 NULL,
                                                 GL_TEXTURE_2D,
                                                 GL_RED_EXT,
                                                 (GLsizei)frameWidth,
                                                 (GLsizei)frameHeight,
                                                 GL_RED_EXT,
                                                 GL_UNSIGNED_BYTE,
                                                 0,
                                                 &_cvTexturesRef[0]);
    _texYUVVT[0] = CVOpenGLESTextureGetName(_cvTexturesRef[0]);
    glBindTexture(CVOpenGLESTextureGetTarget(_cvTexturesRef[0]), _texYUVVT[0]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                 _textureCache,
                                                 pixelBuffer,
                                                 NULL,
                                                 GL_TEXTURE_2D,
                                                 GL_RG_EXT,
                                                 (GLsizei)frameWidth / 2,
                                                 (GLsizei)frameHeight / 2,
                                                 GL_RG_EXT,
                                                 GL_UNSIGNED_BYTE,
                                                 1,
                                                 &_cvTexturesRef[1]);
    _texYUVVT[1] = CVOpenGLESTextureGetName(_cvTexturesRef[1]);
    glBindTexture(CVOpenGLESTextureGetTarget(_cvTexturesRef[1]), _texYUVVT[1]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    for (int i = 0; i < 2; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _texYUVVT[i]);
        glUniform1i(_uniformYUVVT[i], i);
    }
    
    glUniformMatrix3fv(_uniformVT, 1, GL_FALSE, _preferredConversion);
    [super updateProjectionMatrix];
}

#pragma mark - Handle shaders ~ compile & bind attr,uniforms

- (int)compileShaderAndLinkProgram {
    
    _vertexShader = 0, _fragmentShader = 0;
    
    _vertexShader = [super compileShader:stringShaderVertex
                                withType:GL_VERTEX_SHADER];
    if (_vertexShader == -1)
        return -1;
    
    _fragmentShader = [super compileShader:stringShaderFragmentYUVVT
                                  withType:GL_FRAGMENT_SHADER];
    
    if (_fragmentShader == -1)
        return -1;
    
    int err = [super linkProgram];
    
    if (err != 0)
        return -1;
    
    _uniformYUVVT[0] = glGetUniformLocation(_program, "s_texture_y");
    _uniformYUVVT[1] = glGetUniformLocation(_program, "s_texture_uv");
    _uniformVT = glGetUniformLocation(_program, "colorConversionMatrix");
    _projectionUniformMatrix = glGetUniformLocation(_program, "projectionMatrix");

    return 0;
}

- (void)dealloc {
    
    if (_textureCache) {
        CFRelease(_textureCache);
        _textureCache = 0;
    }
    
    [super dealloc];
}


@end
