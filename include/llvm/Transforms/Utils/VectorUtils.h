//===- llvm/Transforms/Utils/VectorUtils.h - Vector utilities -*- C++ -*-=====//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines some vectorizer utilities.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_UTILS_VECTORUTILS_H
#define LLVM_TRANSFORMS_UTILS_VECTORUTILS_H

namespace llvm {

/// \brief Identify if the intrinsic is trivially vectorizable.
///
/// This method returns true if the intrinsic's argument types are all
/// scalars for the scalar form of the intrinsic and all vectors for
/// the vector form of the intrinsic.
static inline bool isTriviallyVectorizable(Intrinsic::ID ID) {
  switch (ID) {
  case Intrinsic::sqrt:
  case Intrinsic::sin:
  case Intrinsic::cos:
  case Intrinsic::exp:
  case Intrinsic::exp2:
  case Intrinsic::log:
  case Intrinsic::log10:
  case Intrinsic::log2:
  case Intrinsic::tan:
  case Intrinsic::asin:
  case Intrinsic::acos:
  case Intrinsic::atan:
  case Intrinsic::atan2:
  case Intrinsic::cbrt:
  case Intrinsic::sinh:
  case Intrinsic::cosh:
  case Intrinsic::tanh:
  case Intrinsic::asinh:
  case Intrinsic::acosh:
  case Intrinsic::atanh:
  case Intrinsic::exp10:
  case Intrinsic::expm1:
  case Intrinsic::log1p:
  case Intrinsic::fabs:
  case Intrinsic::copysign:
  case Intrinsic::floor:
  case Intrinsic::ceil:
  case Intrinsic::trunc:
  case Intrinsic::rint:
  case Intrinsic::nearbyint:
  case Intrinsic::round:
  case Intrinsic::ctpop:
  case Intrinsic::pow:
  case Intrinsic::fma:
  case Intrinsic::fmuladd:
    return true;
  default:
    return false;
  }
}

} // llvm namespace

#endif
