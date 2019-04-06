//
//  BBMetalLinearBurnBlendFilter.swift
//  BBMetalImage
//
//  Created by Kaibo Lu on 4/6/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

/// Applies a linear burn blend of two images
public class BBMetalLinearBurnBlendFilter: BBMetalBaseFilter {
    public init() { super.init(kernelFunctionName: "linearBurnBlendKernel") }
    override func updateParameters(forComputeCommandEncoder encoder: MTLComputeCommandEncoder) {}
}
