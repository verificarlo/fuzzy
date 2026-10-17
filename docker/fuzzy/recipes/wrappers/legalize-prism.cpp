// Split only FP vector operations absent from PRISM's released ABI. Keep
// element order, fast-math flags, and the original surrounding vector IR.
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/MathExtras.h"
#include <algorithm>
using namespace llvm;

namespace {
struct LegalizePRISM : PassInfoMixin<LegalizePRISM> {
  static bool isRequired() { return true; }
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    SmallVector<Instruction *> Work;
    for (auto &B : F)
      for (auto &I : B) {
        auto *T = dyn_cast<FixedVectorType>(I.getType());
        if (!T || (!T->getElementType()->isFloatTy() &&
                   !T->getElementType()->isDoubleTy()))
          continue;
        unsigned N = T->getNumElements();
        if (N >= 2 && isPowerOf2_32(N) && N <= 32)
          continue;
        bool Binary = I.getOpcode() == Instruction::FAdd ||
                      I.getOpcode() == Instruction::FSub ||
                      I.getOpcode() == Instruction::FMul ||
                      I.getOpcode() == Instruction::FDiv;
        auto *Call = dyn_cast<IntrinsicInst>(&I);
        if (Binary || (Call && (Call->getIntrinsicID() == Intrinsic::fma ||
                               Call->getIntrinsicID() == Intrinsic::fmuladd)))
          Work.push_back(&I);
      }
    for (auto *I : Work) {
      auto *T = cast<FixedVectorType>(I->getType());
      auto *Element = T->getElementType();
      unsigned N = T->getNumElements();
      unsigned Max = FUZZY_VECTOR_BITS / Element->getScalarSizeInBits();
      IRBuilder<> B(I);
      B.SetCurrentDebugLocation(I->getDebugLoc());
      B.setFastMathFlags(I->getFastMathFlags());
      Value *Result = PoisonValue::get(T);
      auto *Call = dyn_cast<IntrinsicInst>(I);
      for (unsigned Start = 0; Start < N;) {
        unsigned Count = 1u << Log2_32(std::min(Max, N - Start));
        SmallVector<Value *> Args;
        unsigned Arity = Call ? Call->arg_size() : 2;
        for (unsigned A = 0; A < Arity; ++A) {
          Value *V = I->getOperand(A);
          if (Count == 1) {
            Args.push_back(B.CreateExtractElement(V, Start));
          } else {
            SmallVector<int> Mask;
            for (unsigned J = 0; J < Count; ++J)
              Mask.push_back(Start + J);
            Args.push_back(B.CreateShuffleVector(V, Mask));
          }
        }
        Value *Chunk;
        if (Call)
          Chunk = B.CreateIntrinsic(Call->getIntrinsicID(), {Args[0]->getType()}, Args);
        else
          Chunk = B.CreateBinOp(static_cast<Instruction::BinaryOps>(I->getOpcode()),
                                Args[0], Args[1]);
        for (unsigned J = 0; J < Count; ++J) {
          Value *Lane = Count == 1 ? Chunk : B.CreateExtractElement(Chunk, J);
          Result = B.CreateInsertElement(Result, Lane, Start + J);
        }
        Start += Count;
      }
      I->replaceAllUsesWith(Result);
      I->eraseFromParent();
    }
    return Work.empty() ? PreservedAnalyses::all() : PreservedAnalyses::none();
  }
};
}
extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "fuzzy-prism-legalize", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &PM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name != "fuzzy-prism-legalize") return false;
                  PM.addPass(LegalizePRISM());
                  return true;
                });
          }};
}
