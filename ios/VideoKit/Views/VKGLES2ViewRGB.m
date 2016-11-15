//
//  VKGLES2ViewRGB.m
//  VideoKitSample
//
//  Created by Murat Sudan on 19/08/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKGLES2ViewRGB.h"

NSString *const stringShaderFragmentRGB = SHADER_STRING
(
 varying highp vec2 texCoordOut;
 uniform sampler2D s_texture_rgb;
 
 void main()
 {
     gl_FragColor = texture2D(s_texture_rgb, texCoordOut);
 }
 );

@interface VKGLES2View ()
- (void)renderFrameToTexture:(VKVideoFrame *)vidFrame;
- (void)updateProjectionMatrix;
- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType;
- (int)linkProgram;
@end

@interface VKGLES2ViewRGB () {
    GLint _uniformRGB;  // Uniform for each RGB
    GLuint _texRGB;     // Texture id for each RGB
}

@end

@implementation VKGLES2ViewRGB

- (int)initGLWithDecodeManager:(VKDecodeManager *)decoder bounds:(CGRect)bounds {
    
    int err = [super initGLWithDecodeManager:decoder bounds:bounds];
    if (err == 0) {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
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
        [self renderFrame:(VKVideoFrameRGB *)vidFrame];
    }
    
    if (0 != _texRGB) {
        glVertexAttribPointer(_position, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(_position);
        glVertexAttribPointer(_texCoordIn, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(_texCoordIn);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderFrame:(VKVideoFrameRGB *)vidFrame {
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _texRGB)
        glGenTextures(1, &_texRGB);
    
    glBindTexture(GL_TEXTURE_2D, _texRGB);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, vidFrame.width, vidFrame.height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, vidFrame.pRGB.data);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texRGB);
    glUniform1i(_uniformRGB, 0);
    
    [super updateProjectionMatrix];
}

#pragma mark - Handle shaders ~ compile & bind attr,uniforms

- (int)compileShaderAndLinkProgram {
    
    _vertexShader = 0, _fragmentShader = 0;
    
    _vertexShader = [super compileShader:stringShaderVertex
                                withType:GL_VERTEX_SHADER];
    if (_vertexShader == -1)
        return -1;
    
    _fragmentShader = [super compileShader:stringShaderFragmentRGB
                                  withType:GL_FRAGMENT_SHADER];
    
    if (_fragmentShader == -1)
        return -1;
    
    int err = [super linkProgram];
    
    if (err != 0)
        return -1;
    
    _uniformRGB = glGetUniformLocation(_program, "s_texture_rgb");
    
    return 0;
}

- (void)dealloc {
    [super dealloc];
}

@end
