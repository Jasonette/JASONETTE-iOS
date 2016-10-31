//
//  PBJGLProgram.m
//  PBJVision
//
//  Created by Patrick Piemonte on 4/9/14.
//  Copyright (c) 2013-present, Patrick Piemonte, http://patrickpiemonte.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "PBJGLProgram.h"

NSString * const PBJGLProgramAttributeVertex = @"a_position";
NSString * const PBJGLProgramAttributeTextureCoord = @"a_texture";
NSString * const PBJGLProgramAttributeNormal = @"a_normal";

@interface PBJGLProgram ()
{
    GLuint _program;
    GLuint _vertShader;
    GLuint _fragShader;
    
    NSString *_vertexShaderName;
    NSString *_fragmentShaderName;
    NSMutableArray *_attributes;
}

@end

@implementation PBJGLProgram

- (id)initWithVertexShaderName:(NSString *)vertexShaderName fragmentShaderName:(NSString *)fragmentShaderName;
{
    self = [super init];
    if (self) {
        _program = glCreateProgram();
        
        _vertexShaderName = vertexShaderName;
        if (![self _compileShader:&_vertShader type:GL_VERTEX_SHADER file:vertexShaderName]) {
            NSLog(@"failed to compile vertex shader");
        }
        
        _fragmentShaderName = fragmentShaderName;
        if (![self _compileShader:&_fragShader type:GL_FRAGMENT_SHADER file:fragmentShaderName]) {
            NSLog(@"failed to compile fragment shader");
        }
        
        glAttachShader(_program, _vertShader);
        glAttachShader(_program, _fragShader);
        
        _attributes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if (_vertShader) {
        glDeleteShader(_vertShader);
    }
    
    if (_fragShader) {
        glDeleteShader(_fragShader);
    }

    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}


- (BOOL)_compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

#pragma mark -

- (void)addAttribute:(NSString *)attributeName
{
    if (![_attributes containsObject:attributeName]) {
        [_attributes addObject:attributeName];
        GLuint index = [self attributeLocation:attributeName];
        glBindAttribLocation(_program, index, [attributeName UTF8String]);
    }
}

- (GLuint)attributeLocation:(NSString *)attributeName
{
    return (GLuint)[_attributes indexOfObject:attributeName];
}

- (int)uniformLocation:(NSString *)uniformName
{
    return glGetUniformLocation(_program, [uniformName UTF8String]);
}

- (BOOL)link
{
    GLint status;
    
    glLinkProgram(_program);
    glValidateProgram(_program);
    
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSLog(@"failed to link program, %d", _program);
        return NO;
    }
    
    if (_vertShader) {
        glDeleteShader(_vertShader);
        _vertShader = 0;
    }
    
    if (_fragShader) {
        glDeleteShader(_fragShader);
        _fragShader = 0;
    }
    
    return NO;
}

- (void)use
{
    glUseProgram(_program);
}

@end
