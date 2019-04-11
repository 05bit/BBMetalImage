//
//  BBMetalPolarPixellateFilter.metal
//  BBMetalImage
//
//  Created by Kaibo Lu on 4/10/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

#include <metal_stdlib>
#include "BBMetalShaderTypes.h"
using namespace metal;

kernel void polarPixellateKernel(texture2d<half, access::write> outputTexture [[texture(0)]],
                                 texture2d<half, access::sample> inputTexture [[texture(1)]],
                                 device float2 *pixelSize [[buffer(0)]],
                                 device float2 *center [[buffer(1)]],
                                 uint2 gid [[thread_position_in_grid]]) {
    
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) { return; }
    
    const float2 textureCoordinate = float2(float(gid.x) / inputTexture.get_width(), float(gid.y) / inputTexture.get_height());
    float2 normCoord = 2.0 * textureCoordinate - 1.0;
    const float2 normCenter = 2.0 * float2(*center) - 1.0;
    
    normCoord -= normCenter;
    
    float r = length(normCoord); // to polar coords
    float phi = atan2(normCoord.y, normCoord.x); // to polar coords
    
    float2 size = float2(*pixelSize);
    r = r - mod(r, size.x) + 0.03;
    phi = phi - mod(phi, size.y);
    
    normCoord.x = r * cos(phi);
    normCoord.y = r * sin(phi);
    
    normCoord += normCenter;
    
    const float2 textureCoordinateToUse = normCoord / 2.0 + 0.5;
    
    constexpr sampler quadSampler;
    const half4 outColor = inputTexture.sample(quadSampler, textureCoordinateToUse);
    outputTexture.write(outColor, gid);
}
