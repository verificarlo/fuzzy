; ModuleID = 'test.1.ll'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [8 x i8] c"%0.17f\0A\00", align 1
@_vfc_current_mca_interface = external global { float (float, float)*, float (float, float)*, float (float, float)*, float (float, float)*, i1 (float, float, i8)*, double (double, double)*, double (double, double)*, double (double, double)*, double (double, double)*, i1 (double, double, i32)* }

; Function Attrs: nounwind uwtable
define i32 @main() #0 {
  %1 = alloca i32, align 4
  %a = alloca double, align 8
  %i = alloca i32, align 4
  store i32 0, i32* %1
  store double 0.000000e+00, double* %a, align 8
  store i32 0, i32* %i, align 4
  br label %2

; <label>:2                                       ; preds = %9, %0
  %3 = load i32* %i, align 4
  %4 = icmp slt i32 %3, 10000
  br i1 %4, label %5, label %12

; <label>:5                                       ; preds = %2
  %6 = load double* %a, align 8
  %7 = load double (double, double)** getelementptr inbounds ({ float (float, float)*, float (float, float)*, float (float, float)*, float (float, float)*, i1 (float, float, i8)*, double (double, double)*, double (double, double)*, double (double, double)*, double (double, double)*, i1 (double, double, i32)* }* @_vfc_current_mca_interface, i32 0, i32 5)
  %8 = call double %7(double %6, double 1.000000e-01)
  store double %8, double* %a, align 8
  br label %9

; <label>:9                                       ; preds = %5
  %10 = load i32* %i, align 4
  %11 = add nsw i32 %10, 1
  store i32 %11, i32* %i, align 4
  br label %2

; <label>:12                                      ; preds = %2
  %13 = load double* %a, align 8
  %14 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([8 x i8]* @.str, i32 0, i32 0), double %13)
  ret i32 0
}

declare i32 @printf(i8*, ...) #1

attributes #0 = { nounwind uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = metadata !{metadata !"Ubuntu clang version 3.5.0-4ubuntu2~trusty2 (tags/RELEASE_350/final) (based on LLVM 3.5.0)"}
