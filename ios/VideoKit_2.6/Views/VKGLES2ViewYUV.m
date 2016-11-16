//
//  VKGLES2ViewYUV.m
//  VideoKitSample
//
//  Created by Murat Sudan on 19/08/16.
//  Copyright © 2016 iosvideokit. All rights reserved.
//

#import "VKGLES2ViewYUV.h"

NSString *const stringShaderFragmentYUV = SHADER_STRING
(
 precision highp float;
 varying highp vec2 texCoordOut;
 uniform sampler2D s_texture_y;
 uniform sampler2D s_texture_u;
 uniform sampler2D s_texture_v;
 
 const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     highp float y = (texture2D(s_texture_y, texCoordOut).r - 0.06274509804) * 1.164;
     highp float u = texture2D(s_texture_u, texCoordOut).r - 0.5;
     highp float v = texture2D(s_texture_v, texCoordOut).r - 0.5;
     
     highp float r = y + 1.596 * v;
     highp float g = y - 0.391 * u - 0.813 * v;
     highp float b = y + 2.018 * u;
     
     gl_FragColor = vec4(vec3(r,g,b),1.0);
 }
 );

@interface VKGLES2View ()
- (void)renderFrameToTexture:(VKVideoFrame *)vidFrame;
- (void)updateProjectionMatrix;
- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType;
- (int)linkProgram;
@end

@interface VKGLES2ViewYUV () {
    GLint _uniformYUV[3];  // Uniforms for each Y,U,V
    GLuint _texYUV[3];     // Texture ids for each Y,U,V
}

@end

@implementation VKGLES2ViewYUV

- (int)initGLWithDecodeManager:(VKDecodeManager *)decoder bounds:(CGRect)bounds {
    
    int err = [super initGLWithDecodeManager:decoder bounds:bounds];
    if (err == 0) {        
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
        [self renderFrame:(VKVideoFrameYUV *)vidFrame];
    }
    
    if (0 != _texYUV[0]) {
        glVertexAttribPointer(_position, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(_position);
        glVertexAttribPointer(_texCoordIn, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(_texCoordIn);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderFrame:(VKVideoFrameYUV *)vidFrame {
    BOOL texNotCreated = NO;
    const NSUInteger frameWidth = vidFrame.width;
    const NSUInteger frameHeight = vidFrame.height;
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _texYUV[0]) {
        texNotCreated = YES;
        glGenTextures(3, _texYUV);
    }
    
    const UInt8 *pixels[3] = { vidFrame.pLuma.data, vidFrame.pChromaB.data, vidFrame.pChromaR.data };
    const NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
    const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _texYUV[i]);
        
        if (texNotCreated) {
            glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (int)widths[i], (int)heights[i],
                         0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels[i]);
        } else {
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0,
                            (int)widths[i], (int)heights[i], GL_LUMINANCE, GL_UNSIGNED_BYTE, pixels[i]);
        }
        glUniform1i(_uniformYUV[i], i);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    [super updateProjectionMatrix];
}

#pragma mark - Handle shaders ~ compile & bind attr,uniforms

- (int)compileShaderAndLinkProgram {
    
    _vertexShader = 0, _fragmentShader = 0;
    
    _vertexShader = [super compileShader:stringShaderVertex
                                withType:GL_VERTEX_SHADER];
    if (_vertexShader == -1)
        return -1;
    
    _fragmentShader = [super compileShader:stringShaderFragmentYUV
                                  withType:GL_FRAGMENT_SHADER];
    
    if (_fragmentShader == -1)
        return -1;
    
    int err = [super linkProgram];
    
    if (err != 0)
        return -1;
    
    _uniformYUV[0] = glGetUniformLocation(_program, "s_texture_y");
    _uniformYUV[1] = glGetUniformLocation(_program, "s_texture_u");
    _uniformYUV[2] = glGetUniformLocation(_program, "s_texture_v");
    
    return 0;
}

- (void)dealloc {
    [super dealloc];
}

@end
